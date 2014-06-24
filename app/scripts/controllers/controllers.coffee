"use strict"

# Controllers 

app =  angular.module("gifpumper")


app.controller "spaceCtrl" , ($scope, $rootScope)->
  $rootScope.edit = false;



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
      now.submitComment $scope.pageName, textObject, $scope.currentUser.name 
      $scope.newText = ""
    return











app.controller "elController",($scope, elService) ->
  
  $scope.elementFeed = ()->
    elService.elementFeed $scope.pageName, $scope.el
  
  $scope.editElementFn = (options)->
    if($scope.el)
      elService.editElement options, $scope.el, (err)->
        console.log(err)

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


app.controller "activeCtrl", ($scope, activePages)->
  $scope.onlineList={}
  $scope.renderList={}

  activePages.getAllUsersOnline (res)->
    for user in res 
      if !$scope.onlineList[user.page._id]  
        $scope.onlineList[user.page._id] = {}
        $scope.onlineList[user.page._id].data = user.page
        $scope.onlineList[user.page._id].users=[]
      $scope.onlineList[user.page._id].users.push(user.user)
      $scope.renderList[user.page._id] =  $scope.onlineList[user.page._id]  


  activePages.on 'updateFeed', (user, pageName, page, action) ->
    return  if page is `undefined`
    return  if pageName and pageName.split("profile___")[0] is "" or pageName is "main"
    if action is "leave" && $scope.onlineList[page]
      n = $scope.onlineList[page].users.indexOf(user)
      $scope.onlineList[page].users.splice n, 1
      if $scope.onlineList[page].users.length == 0
        delete $scope.onlineList[page]
        delete $scope.renderList[page]

    else if action is "join"
      if $scope.onlineList[page] is `undefined`
        $scope.onlineList[page] = {}
        # $scope.onlineList[page].data=pageData
        $scope.onlineList[page].users = []
      if $scope.onlineList[page].users.indexOf(user) <0
        $scope.onlineList[page].users.push user

      activePages.getPageData page, (res)->
        $scope.onlineList[page].data=res 
        $scope.renderList[page]=$scope.onlineList[page]
        $scope.$apply() 

    # console.log image
    return



app.controller "onlineCtrl", ($scope, currentUser, $rootScope)->
  
  # $scope.onlineUsers=currentUser.getOnlineUsers.onlineUsers
  # $scope.noobs = currentUser.getOnlineUsers.noobs

  $scope.onlineUsers={}
  $scope.noobs =0


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
        for i, user of group
          if i == 'n00b'
            $scope.noobs++
          else if !$scope.onlineUsers[user]
            $scope.onlineUsers[user.name] = user



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
    $scope.$parent.pageData = $scope.userData
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


  bg = document.getElementById('background')
  udpateBackground=(clear)->
    if clear 
      bg.style.backgroundColor = ""
      bg.style.backgroundImage = ""
      return
    style= $filter('bgFilter')($scope.userData)
    bg.style.backgroundSize = style.backgroundSize
    bg.style.backgroundColor = style.backgroundColor
    angular.element(bg).css 
      'background-image': style.backgroundImage
    # body.style.backgroundImage = style.backgroundImage
    b = 0
    while b < style.backgroundGradient.length
      bg.style.backgroundImage += style.backgroundGradient[b]
      b++

  # udpateBackground(true)

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
  
  theEnd = false

  $scope.getNextPage = ()->
    if theEnd
      return;
    $scope.scroll = false
    feed.getNextPage().then (result) ->

      console.log(result)
      if result.length == 0
        theEnd = true;

      $scope.feed = $scope.feed.concat(result)

      $scope.filteredFeed = $filter('feedFilter')($scope.feed)
      # $scope.filteredFeed = $scope.feed
      # console.log($scope.feed);
      $scope.scroll = true
      $scope.loading=false
      if $scope.filteredFeed.length<8 && $scope.filteredFeed.length
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

