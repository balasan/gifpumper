"use strict"

# Page Controller 
app =  angular.module("gifpumper")


app.controller "pageCtrl", ($scope, pageService, $location, $route, $filter, $rootScope, pageCache, userService) ->

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
  

  $scope.openEditor = () ->
    $scope.editMenu = true;


  $scope.setPrivacy = () ->
    pageService.setPrivacy $scope.pageName, $scope.pageData.privacy, null, (err)->
      if err 
        alert err

  $scope.deletePage = ()->
    pageService.deletePage $scope.pageData._id, (err)->
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

  

  $scope.setBackground = (options) ->
    bg =
      color: $scope.pageData.background
      image: $scope.pageData.backgroundImage
      display: $scope.pageData.bgDisplay

    updateBackground()
    if options && options.server
      if $scope.pageName == 'profile'
        userService.setBackground bg, options, (err)->
          if err 
            console.log(err)
      else
        pageService.setBackground(bg, options)


      
  pageService.on 'updateBackground',(bg)->
    img = new Image()
    img.src = bg.image
    img.onload = ()->
      $scope.pageData.backgroundImage = bg.image
      # TODO: fix flash
      updateBackground()
      img = null
    if !bg.imgOnly
      $scope.pageData.background = bg.color
      $scope.pageData.bgDisplay = bg.display
    updateBackground()




  $scope.updateElement = (elArray, options)->
    for el in elArray
      index = $filter('getById')($scope.pageData.images,el._id)
      if(index != undefined)
        if options && options.replaceUrl
          for key, value of el
            $scope.pageData.images[index][key] = value        
        else
          el.url = $scope.pageData.images[index].url
          for key, value of el
            $scope.pageData.images[index][key] = value 
      else $scope.pageData.images.push(el)
      # $scope.apply()
    return

  pageService.on('updateElement', $scope.updateElement)


  pageService.on('newElement', $scope.updateElement)



  $scope.deleteElement = (elId, all)->
    if all
      pageData.images=[]
    else
      index = $filter('getById')($scope.pageData.images,elId)
      $scope.pageData.images.splice(index, 1);
    $rootScope.selected= null
  
  pageService.on('deleteResponce', $scope.deleteElement)


  $scope.addNewImgCtrl = (options ,elArray)->
    pageService.addNewImg options, elArray, (err)->
      console.log(err)



  $scope.saveScroll = (scroll) ->
    pageCache.saveScroll($scope.pageName, scroll)
    $scope.scroll = scroll


  bg = document.getElementById('background')
  updateBackground=(clear)->
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
        updateBackground()
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
    updateBackground(true)

    # $scope.saveScroll = (scroll) ->
    #   pageCache.saveScroll($scope.pageName, scroll)
    #   $scope.scroll = scroll

    $scope.pageData = pageCache.getPage $scope.pageName

    if !$scope.pageData
      pageService.getData($scope.pageName,$scope.userProfile,$scope.pageVersion).then (result) ->
        if result.pageName != $scope.pageName
          return;
        $scope.maxVersion = result.currentVersion
        if(!$scope.pageVersion)
          $scope.pageData = result
        else
          $scope.pageData = result.versions[0]
        updateBackground();
        console.log($scope.pageData)
        if $scope.pageData.likes
          $scope.likesPage = $scope.pageData.likes.indexOf($rootScope.currentUser.name)>-1
        if $scope.pageData.pageName == 'main'
          pageCache.savePage($scope.pageData.pageName, $scope.pageData)    
    else
      # $scope.scroll = pageCache.getScroll $scope.pageName
      pageService.getData($scope.pageName,$scope.userProfile,$scope.pageVersion)
      updateBackground();
      if $scope.pageData.likes
        $scope.likesPage = $scope.pageData.likes.indexOf($rootScope.currentUser.name)>-1
    
  $scope.$on "$destroy", ()->
 
