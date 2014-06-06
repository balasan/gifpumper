"use strict"

# Page Controller 
app =  angular.module("gifpumper")


app.controller "pageCtrl", ($scope, pageService, $location, $route, $filter, $rootScope, pageCache) ->

  $scope.mt=
    rotY:0
    rotX:0
    rotZ:0
    x:0
    z:0
    y:0

  currentPage = null;
  $scope.likePage = (likesPage, callback) ->
    action
    if !likesPage
      action = 'like'
    else action = 'unlike'
    currentPage = $scope.pageName
    pageService.likePage action, $scope.pageName.version, (err, action)->
      if err then alert(err)
      else if currentPage == $scope.pageName
        if action == "unlike"
          i = $scope.pageData.likes.indexOf($rootScope.currentUser.name)
          $scope.pageData.likes.splice(i,1)
          $scope.likesPage = false;
        else if action == 'like'
          $scope.pageData.likes.push($rootScope.currentUser.name)
          $scope.likesPage = true;

      # callback() 
  
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
    desiredPageName = desiredPageName.trim()
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



  $scope.saveScroll = (scroll) ->
    pageCache.saveScroll($scope.pageName, scroll)
    $scope.scroll = scroll


  bg = document.getElementById('background')
  udpateBackground=(clear)->
    if clear 
      bg.style.backgroundColor = ""
      bg.style.backgroundImage = ""
      return
    style= $filter('bgFilter')($scope.pageData)
    bg.style.backgroundSize = style.backgroundSize
    bg.style.backgroundColor = style.backgroundColor
    angular.element(bg).css 
      'background-image': style.backgroundImage
    # body.style.backgroundImage = style.backgroundImage
    b = 0
    while b < style.backgroundGradient.length
      bg.style.backgroundImage += style.backgroundGradient[b]
      b++


  $scope.location = $location
  # $scope.pageData = {};
  $scope.$watch 'location.path()', (path) ->
    $scope.pageName = path.split('/')[1]
    
    if $scope.pageName == ""
      $scope.showMain = true
      if $scope.pageData
        udpateBackground()
    else
      $scope.showMain = false

    if $scope.pageName == 'profile'
      $scope.pageData = {}
      $scope.userProfile = path.split('/')[2]
      return;

    path = $scope.location.path()
    console.log path
    $scope.pageName = path.split('/')[1]
    $scope.userProfile = ""
    $scope.pageVersion = ""
    $rootScope.selected= null

    $scope.pageVersion = path.split('/')[2]
    if $scope.pageName == ""
      $scope.pageName = 'main'
    $scope.pageData = {}
    udpateBackground(true)

    # $scope.saveScroll = (scroll) ->
    #   pageCache.saveScroll($scope.pageName, scroll)
    #   $scope.scroll = scroll

    $scope.pageData = pageCache.getPage $scope.pageName

    if !$scope.pageData
      pageService.getData($scope.pageName,$scope.userProfile,$scope.pageVersion).then (result) ->
        if result.pageName != $scope.pageName
          return;
        $scope.pageData = result
        udpateBackground();
        console.log($scope.pageData)
        if $scope.pageData.likes
          $scope.likesPage = $scope.pageData.likes.indexOf($rootScope.currentUser.name)>-1
        if $scope.pageData.pageName == 'main'
          pageCache.savePage($scope.pageData.pageName, $scope.pageData)    
    else
      # $scope.scroll = pageCache.getScroll $scope.pageName
      pageService.getData($scope.pageName,$scope.userProfile,$scope.pageVersion)
      udpateBackground();
      if $scope.pageData.likes
        $scope.likesPage = $scope.pageData.likes.indexOf($rootScope.currentUser.name)>-1
    
  $scope.$on "$destroy", ()->
 
