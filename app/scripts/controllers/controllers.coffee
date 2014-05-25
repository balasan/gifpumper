"use strict"

# Controllers 

app =  angular.module("gifpumper")



app.controller "chatCtrl" , ($scope, nowService)->
  $scope.enterTest='adsfkajdfa'

  nowService.on 'updateText', (user, text)->
    $scope.pageData.text.push
      user:user 
      text:text

  $scope.enterText = (evt) ->
    charCode = (if (evt.which) then evt.which else window.event.keyCode)
    if charCode is 13
      if $scope.username  is "n00b" and pageName isnt "invite"
        alert "YOU HAVE TO LOG IN TO DO POST COMMENTS"
        inputBox = document.getElementById("inputBox")
        inputBox.value = ""
        return
      evt.preventDefault()
      textObject = {}
      textObject.text = $scope.newText
      textObject.time = new Date()
      now.submitComment $scope.pageName, textObject, $scope.username 
      $scope.newText = ""
    return











app.controller "elController",($scope, elService) ->
  $scope.elementFeed = ()->
    elService.elementFeed $scope.pageName, $scope.el
  $scope.editElementFn = ()->
    isPosition = true;
    if($scope.el)
      elService.editElement $scope.pageName, $scope.el, isPosition

  $scope.deleteElement = ()->
    elService.deleteElement $scope.pageName, $scope.el







# logout and right menu controller
app.controller "mainCtrl",($scope, currentUser,$rootScope, Auth, $filter) ->


  $scope.notify = []
  $scope.notifyFiltered=[];
  $scope.newN = 0;
  $scope.loginMenu = false;

  $scope.user = {}
  $scope.errors = {}
  $rootScope.loggedIn = false



  if $rootScope.currentUser.name != 'n00b'
    $rootScope.loggedIn = true


  currentUser.on "notifyUser", (notify, newN)->
    $scope.notify = $scope.notify.concat(notify)
    $scope.notifyFiltered = $filter('feedFilter')($scope.notify)
    $scope.newN += newN 
    # console.log(notify)

  $scope.logOut = ->
    Auth.logout().then ->
      $rootScope.loggedIn = false;


  # text editor
  $scope.editorOptions =
    language: 'en',
    uiColor: '#ffffff',


  #TODO reset notify when opening notifications


  # currentUser.getCurrentUser (username)->
  #   console.log("GOT USER: " + username)
  #   $scope.username = username 
  #   if($scope.username && $scope.username != 'n00b')
  #     $scope.loggedIn = true
  #   else
  #     $scope.loggedIn = false
  #   $scope.$apply()




app.controller "onlineCtrl", ($scope, currentUser, $rootScope)->
  $scope.onlineUsers={}

  $scope.noobs = 0

  currentUser.on 'updatePageUser', (action, users) ->
    if action == 'replace'
       $scope.onlineUsers = {}
       $scope.noobs = 0; 

    # not obj if delete
    if action == 'delete'
      delete $scope.onlineUsers[users]
      if users == 'n00b'
        $scope.noobs--
    else
      for key, group of users
        for user of group
          if user == 'n00b'
            $scope.noobs++
          else if !$scope.onlineUsers[user]
            $scope.onlineUsers[user] = user



    $scope.$on 'logout', ()->
      $scope.onlineUsers={}
 

  # $rootScope.clearUsers = ()->
    # $scope.onlineUsers={}






app.controller "userCtrl", ($scope, userService,$routeParams, $filter, pageService) ->

  $scope.userProfile = $routeParams.userName
  currentState = userService.getData()
  $scope.filter = currentState.filter
  $scope.pagesData = currentState.data
  $scope.scroll = true
  $scope.loading=false
  $scope.userData = {}
  $scope.pageName = 'profile'
  $scope.editType = "image"

  $scope.editElementFn = ()->
    userService.updateUserPic $scope.userProfile, $scope.editElement.url, (err)->
      if !err 
        $scope.userData.userImage = $scope.editElement.url 
        $scope.$apply()   

  userService.getUserData($scope.userProfile).then (result) ->
    $scope.userData = result;
    $scope.pageData = $scope.userData
    udpateBackground()
    # some hacks to make editing work
    $scope.editElement ={}
    $scope.editElement.url = $scope.userData.userImage
    $scope.editElement._id = 'profileImage'

    # console.log(result)


  # background stuff is redundant - separate controller?
  $scope.setBackground = () ->
    bg =
      color: $scope.pageData.background
      image: $scope.pageData.backgroundImage
      display: $scope.pageData.bgDisplay
    userService.setBackground($scope.userProfile,bg)
    
  userService.on 'updateBackground',(bg)->
    $scope.pageData.backgroundImage = bg.image
    $scope.pageData.background = bg.color
    $scope.pageData.bgDisplay = bg.display
    udpateBackground()


  body = document.body
  udpateBackground=(clear)->
    if clear 
      body.style.backgroundColor = ""
      body.style.backgroundImage = ""
      return
    style= $filter('bgFilter')($scope.userData)
    body.style.backgroundSize = style.backgroundSize
    body.style.backgroundColor = style.backgroundColor
    body.style.backgroundImage = style.backgroundImage
    b = 0
    while b < style.backgroundGradient.length
      body.style.backgroundImage += style.backgroundGradient[b]
      b++

  udpateBackground(true)

  $scope.getNextPage = ()->
    $scope.loading=true
    $scope.scroll = false
    userService.getNextPage($scope.userProfile).then (result) ->
      $scope.pagesData = result
      $scope.loading=false
      $scope.scroll = true
      # console.log($scope.pagesData)

  $scope.$watch 'filter', (newVal, oldVal) ->
    if newVal != oldVal
      userService.switchFilter($scope.filter)
      $scope.pagesData=[]
      $scope.getNextPage()
  if currentState.user != $scope.userProfile
    $scope.filter = 'created'
    $scope.pagesData=[]
    $scope.getNextPage()

  pageService.getData('profile', $scope.userProfile, null).then (result)->
    return








app.controller "feedCtrl", ($scope, feed, $filter) ->

  $scope.filter=""
  $scope.feed = feed.getData()
  $scope.filteredFeed=$filter('feedFilter')($scope.feed)
  $scope.scroll = true
  $scope.loading = false
  
  # feed.on "notifyFeed", (notify)->
  #   $scope.feed = $scope.feed.concat(notify)
  
  $scope.getNextPage = ()->
    $scope.scroll = false
    feed.getNextPage().then (result) ->

      $scope.feed = $scope.feed.concat(result.reverse())
      $scope.filteredFeed = $filter('feedFilter')($scope.feed)
      # console.log($scope.feed);
      $scope.scroll = true
      $scope.loading=false
      if $scope.filteredFeed.length<8
        $scope.getNextPage()

  if !$scope.feed.length
    $scope.getNextPage()


  $scope.$on "$destroy", ()->




app.controller "galleryCtrl", ($scope, galleryService) ->

  currentState = galleryService.getData()
  $scope.filter = currentState.filter
  $scope.pagesData = currentState.data
  $scope.scroll = true
  $scope.loading=false



  $scope.getNextPage = ()->
    $scope.loading=true
    $scope.scroll = false
    galleryService.getNextPage().then (result) =>
      $scope.pagesData = result
      $scope.loading=false
      $scope.scroll = true

  $scope.$watch 'filter', (newVal, oldVal) ->
    if newVal != oldVal
      galleryService.switchFilter($scope.filter)
      $scope.pagesData=[]
      $scope.getNextPage()

  if !$scope.pagesData[0]
    $scope.getNextPage()

  $scope.$on "$destroy", ()->

