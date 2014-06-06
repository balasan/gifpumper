"use strict"

app = angular.module("gifpumper")

uniqueId = ()->
  # Math.random should be unique because of its seeding algorithm.
  # Convert it to base 36 (numbers + letters), and grab the first 9 characters
  # after the decimal.
  return  Math.random().toString(36).substr(2, 9) + "_";


app.controller "uploadCtrl", ($scope, $http, $location, $upload, $rootScope) ->
  
  $http.get('/api/config').success (config)->
    $rootScope.config = config;


  $scope.imageUploads = []

  $scope.abort = (index) ->
    $scope.upload[index].abort()
    $scope.upload[index] = null
    return

  $scope.onFileSelect = ($files) ->
    $scope.files = $files
    $scope.upload = []
    i = 0


    while i < $files.length
      file = $files[i]

      reader = new FileReader();
      reader.onload = (e) ->
        $scope.$parent.newImgUrl =  e.target.result
        $scope.$parent.addNewImg() 
      reader.readAsDataURL(file);



      return;

      file.progress = parseInt(0)
      date = new Date()
      folder = date.getFullYear() + "/" +  (date.getMonth()+1) + '/'
      console.log(folder + uniqueId() + file.name)
      ((file, i) ->
        $http.get("/api/s3Policy?mimeType=" + file.type).success (response) ->
          s3Params = response
          $scope.upload[i] = $upload.upload(
            url: "https://" + $rootScope.config.awsConfig.bucket + ".s3.amazonaws.com/"
            method: "POST"
            data:
              key: folder + uniqueId() + file.name
              acl: "public-read"
              "Content-Type": file.type
              AWSAccessKeyId: s3Params.AWSAccessKeyId
              success_action_status: "201"
              Policy: s3Params.s3Policy
              Signature: s3Params.s3Signature

            file: file
          ).then((response) ->
            file.progress = parseInt(100)
            if response.status is 201
              data = xml2json.parser(response.data)
              parsedData = undefined
              parsedData =
                location: data.postresponse.location
                bucket: data.postresponse.bucket
                key: data.postresponse.key
                etag: data.postresponse.etag

              $scope.imageUploads.push parsedData
            else
              alert "Upload Failed"
            return
          , null, (evt) ->
            file.progress = parseInt(100.0 * evt.loaded / evt.total)
            return
          )
          return

        return
      ) file, i
      i++
    return

  return
