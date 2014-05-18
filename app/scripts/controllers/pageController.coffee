"use strict"

# Page Controller 
app =  angular.module("gifpumper")


app.controller "pageCtrl", ($scope, pageService, $location, $route, $filter, $rootScope) ->

  $scope.mt=
    rotY:0
    rotX:0
    rotZ:0
    x:0
    z:0
    y:0

  
  $scope.setPrivacy = () ->
    pageService.setPrivacy $scope.pageName, $scope.pageData.privacy, null, (err)->
      if err 
        alert err

  $scope.deletePage = ()->
    pageService.deletePage $scope.pageName, (err)->
      if !err 
        $location.path('/')
        $scope.$apply();




  $scope.addPage = (desiredPageName, copyPage) ->
    if copyPage is true
      copyPage = $scope.pageName
    else
      copyPage = null
  
    #TODO: check on server also!
    if desiredPageName.match("/")? or desiredPageName.match("\"")?
      alert "/ and \" are not allowed in page names"
      return
    desiredPageName = $.trim(desiredPageName)
    if desiredPageName is "" or desiredPageName is "%20"
      alert "blank page name"
      return
    desiredPageName = decodeURI(desiredPageName)

    pageService.addPage desiredPageName, copyPage, (error, newPage) ->
      if error
        alert error
      else
        $location.path('/'+newPage);
        $scope.$apply();
      return

  
  $scope.setBackground = () ->
    bg =
      color: $scope.pageData.background
      image: $scope.pageData.backgroundImage
      display: $scope.pageData.bgDisplay
    pageService.setBackground($scope.pageName,bg)
    
  pageService.on 'updateBackground',(bg)->
    $scope.pageData.backgroundImage = bg.image
    $scope.pageData.background = bg.color
    $scope.pageData.bgDisplay = bg.display
    udpateBackground()




  $scope.updateElement = (elArray)->
    for el in elArray
      index = $filter('getById')($scope.pageData.images,el._id)
      if(index != undefined)
        $scope.pageData.images[index] = el 
      else $scope.pageData.images.push(el)
      # $scope.apply()
    return

  pageService.on('newElement', $scope.updateElement)



  $scope.deleteElement = (elId, all)->
    if all
      pageData.images=[]
    else
      index = $filter('getById')($scope.pageData.images,elId)
      $scope.pageData.images.splice(index, 1);
  
  pageService.on('deleteResponce', $scope.deleteElement)


  $scope.addNewImgCtrl = (elArray)->
    pageService.addNewImg($scope.pageName, elArray)





  body = document.body

  udpateBackground=(clear)->
    if clear 
      body.style.backgroundColor = ""
      body.style.backgroundImage = ""
      return
    style= $filter('bgFilter')($scope.pageData)
    body.style.backgroundSize = style.backgroundSize
    body.style.backgroundColor = style.backgroundColor
    body.style.backgroundImage = style.backgroundImage
    b = 0
    while b < style.backgroundGradient.length
      body.style.backgroundImage = style.backgroundGradient[b]
      b++


  $scope.location = $location
  # $scope.pageData = {};
  $scope.$watch 'location.path()', (path) ->
    console.log path
    $scope.pageName = path.split('/')[1]
    $scope.userProfile = ""
    $scope.pageVersion = ""
    $rootScope.selected= null

    if $scope.pageName == "profile"
      $scope.userProfile = path.split('/')[2]
    else
      $scope.pageVersion = path.split('/')[2]
    if $scope.pageName == ""
      $scope.pageName = 'main'
    $scope.pageData = {}
    udpateBackground(true)
    pageService.getData($scope.pageName,$scope.userProfile,$scope.pageVersion).then (result) ->
      $scope.pageData = result
      console.log($scope.pageData)
      udpateBackground();


