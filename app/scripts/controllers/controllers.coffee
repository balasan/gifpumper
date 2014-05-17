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






app.controller "onlineCtrl",($scope,onlineService)->
  $scope.onlineUsers={}
  # ugly
  onlineService.on 'updatePageUser', (action, userArray) ->
    for key, group of userArray
      for user, v of group
        if !$scope.onlineUsers[user] && action == 'add'
          $scope.onlineUsers[user] = user
        else if $scope.onlineUsers[user] != undefined && action == 'remove'
          delete $scope.onlineUsers[user]






app.controller "elController",($scope, elService) ->
  $scope.elementFeed = ()->
    elService.elementFeed $scope.pageName, $scope.el
  $scope.editElement = ()->
    isPosition = true;
    if($scope.el)
      elService.editElement $scope.pageName, $scope.el, isPosition

  $scope.deleteElement = ()->
    elService.deleteElement $scope.pageName, $scope.el






app.controller "mainCtrl",($scope, currentUser) ->
  $scope.username = 'n00b'
  $scope.loggedIn = false

  $scope.notify = []
  $scope.newN = 0;

  currentUser.on "notifyUser", (notify, newN)->
    $scope.notify = $scope.notify.concat(notify)
    $scope.newN += newN 
    console.log(notify)

  #TODO reset notify when opening notifications


  currentUser.getCurrentUser (username)->
    $scope.username = username 
    if($scope.username && $scope.username != 'n00b')
      $scope.loggedIn = true
    else
      $scope.loggedIn = false








app.controller "userCtrl", ($scope, userService,$routeParams) ->

  $scope.userProfile = $routeParams.userName
  currentState = userService.getData()
  $scope.filter = currentState.filter
  $scope.pagesData = currentState.data
  $scope.scroll = true
  $scope.loading=false
  $scope.userData = {}

  userService.getUserData($scope.userProfile).then (result) ->
    $scope.userData = result;

  $scope.getNextPage = ()->
    $scope.loading=true
    $scope.scroll = false
    userService.getNextPage($scope.userProfile).then (result) ->
      $scope.pagesData = result
      $scope.loading=false
      $scope.scroll = true
      console.log($scope.pagesData)

  $scope.$watch 'filter', (newVal, oldVal) ->
    if newVal != oldVal
      userService.switchFilter($scope.filter)
      $scope.pagesData=[]
      $scope.getNextPage()
  if currentState.user != $scope.userProfile
    $scope.filter = 'created'
    $scope.pagesData=[]
    $scope.getNextPage()










app.controller "feedCtrl", ($scope, feed) ->

  $scope.filter=""
  $scope.feed = feed.getData()
  $scope.scroll = true
  $scope.loading = false
  
  # feed.on "notifyFeed", (notify)->
  #   $scope.feed = $scope.feed.concat(notify)
  
  $scope.getNextPage = ()->
    $scope.scroll = false
    feed.getNextPage().then (result) ->
      $scope.feed = $scope.feed.concat(result.reverse())
      # console.log($scope.feed);
      $scope.scroll = true
      $scope.loading=false
  if !$scope.feed.length
    $scope.getNextPage()








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


