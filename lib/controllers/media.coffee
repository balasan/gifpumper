AWS = require('aws-sdk')
request = require('request')
s3 = new AWS.S3(); 

mongoose = require('mongoose')

pageModel = mongoose.model('pageModel')
userModel = mongoose.model('userModel')
mediaModel = mongoose.model('mediaModel')

uniqueId = ()->
  # Math.random should be unique because of its seeding algorithm.
  # Convert it to base 36 (numbers + letters), and grab the first 9 characters
  # after the decimal.
  return 'gifpumper_' + Math.random().toString(36).substr(2, 9) + "_";

module.exports = (everyone, nowjs)->


  uploadToS3 = (media, callback)->
    
    url = media.sourceUrl

    options =
      uri: url
      encoding: 'binary'
    
    request options, (error, response, body) ->
      if error? or response.statusCode isnt 200 
        console.log "failed to get image"
        console.log error
      else 
        body = new Buffer(body, 'binary')
        contentType = response.headers['content-type']

        filename = url.substring(url.lastIndexOf('/')+1);
        filename = filename.replace('+','');

        # filename = encodeURIComponent(filename)

        date = new Date()
        path = date.getFullYear() + "/" + (date.getMonth() + 1) + '/'+ uniqueId() + filename
        console.log(path)
        s3.putObject 
          Body: body
          Key: path
          ContentType: contentType
          ContentEncoding: 'utf8'
          Bucket: process.env.bucket
          ACL: 'public-read'
        , (error, data) ->
          if error?
            console.log "error downloading image to s3: "
            console.log error
            callback(error)
          else 
            console.log "success uploading to s3"
            console.log(data)
            media.localUrl = "https://s3.amazonaws.com/gifpumper-images/" + path
            callback(null, media)


  uploadQue = []
  queInProgress = false

  startQue = ()->
    mediaModel.find
      localUrl : null
    .sort("-date")
    (err,result) ->
      uploadQue = result
      processQue()




  processQue = ()->
    if queInProgress
      return;

    console.log(uploadQue)

    if uploadQue[0] 
      media = uploadQue[0].media
      options = uploadQue[0].options
    if media
      queInProgress = true


      uploadToS3 media, (err, media)->      
        if options.user
          uploadToS3 media, userCallback
          saveMedia(media)
        else        
          uploadToS3 media, pageCallback
          saveMedia(media)


   saveMedia = (media)->
    media.save (err)->
      if !err         
        console.log "processed que element"
        uploadQue.splice(0,1)
        queInProgress=false;
        console.log uploadQue.length + " left in que"
        processQue()


      # mediaModel.update
      #   _id : media.id
      # ,
      #   $set :
      #     localUrl : localUrl
      # , (err)->
      #   if err
      #     console.log (err)
      #   else
      #     console.log "processed que element"
      #     uploadQue.splice(0,1)
      #     queInProgress=false;
      #     console.log uploadQue.length + " left in que"
      #     processQue()


  userCallback = (err, media)->
    console.log "uploaded file to: "+ media.localUrl
    userModel.find
      $or: [
        {
          userImage: media.sourceUrl
        }
        {
          backgroundImage: media.sourceUrl
        }
      ]
    , (err, users) ->
        for user in users
          # swap in local background image 
          if user.backgroundImage == media.sourceUrl
            user.backgroundImage = media.localUrl
            nowjs.getGroup(user.id).now.updateBackground 
              image: media.localUrl
              imgOnly: true
            user.save()
            console.log("updated background image in " + user.username)

          if user.userImage == media.sourceUrl
            user.userImage = media.localUrl
            user.save()
            # TODO: Implement nowjs userpic



  pageCallback = (err, media)->
    # if media.pageId
    console.log "uploaded file to: "+ media.localUrl


    pageModel.find
      $or: [
        {
          "images.url": media.sourceUrl
        }
        {
          backgroundImage: media.sourceUrl
        }
      ]
    , (err, pages) ->
      if !err
        for page in pages

          # swap in local background image 
          if page.backgroundImage == media.sourceUrl
            page.backgroundImage = media.localUrl
            page.save()
            nowjs.getGroup(page._id).now.updateBackground 
              image: media.localUrl
              imgOnly: true
            console.log("updated background image in " + page.pageName)

          # swap in local image
          for image in page.images                  
            if image.url == media.sourceUrl
              image.url = media.localUrl
              page.save()
                # carefull here? closure problem
              nowjs.getGroup(page._id).now.updateElement [image], {replaceUrl:true}
              console.log "updated image in " + page.pageName
          




  startQue()



               

  addToMedia : (img, options) ->
    local = false
    if img.contentType == "image"  
      if !img.url.match('https://gifpumper-images.s3.amazonaws.com/')
        local=false
      else
        local=true
        
      mediaModel.findOne
        $or:[
          {sourceUrl : img.url},
          {localUrl : img.url}
        ]
      , (err, media)->
        if err then console.log err

        updateUserUploads = (mediaId, userId)->
          userModel.update
            _id : userId
          ,
            $push : 
              uploads : mediaId
          , (err)->
            if err 
              console.log err
            else 
              console.log 'updated user uploads' 


        if media && media.localUrl
          console.log 'media entry exists'
          console.log media
          if media.localUrl
            img.url = media.localUrl
          options.callback(img, media.id, options)
        else
          media = new mediaModel
          if options && options.upload
            media.uploadedBy = userId
          media.sourceUrl = img.url
          if local 
            media.localUrl = img.url
            media.uploadedBy = options.userId
            updateUserUploads(media.id,userId)

          media.save (err)->
            console.log 'created media entry'
            console.log media
            options.callback(img, media.id, options)

            console.log "new upload"
            console.log local
            
            if !local
              # upload to S3 que
              uploadQue.push 
                media: media
                options: options
              processQue()
  




