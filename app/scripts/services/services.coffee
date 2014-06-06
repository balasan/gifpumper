"use strict"

# Services 
app = angular.module("gifpumper")


app.factory 'nowService', ($rootScope)->
  now.ready ->
    now.notifyFeed = ()->
      return
    now.updateMain = ()->
      return
  disconnect : ->
    now.core.socketio.socket.disconnect()

  connect : ->
    now.core.socketio.socket.connect()

  on : (eventName, callback)->
    now[eventName] = ()->
      args = arguments
      $rootScope.$apply ->
        # callback args
        callback.apply(null,args)
        # callback.apply socket, args
      # $rootScope.$apply()



app.factory 'onlineService', (nowService)-> 
  on : nowService.on


app.factory 'elService', ()->
  editElement : (pageName, element, isPosition)->
    now.editElement(pageName, element, false, isPosition)
  elementFeed : (pageName, element)->
    now.elementFeed(pageName, element)
  deleteElement : (pageName, element)->
    now.deleteElement(pageName, element._id, false)


app.factory 'currentUser', (nowService, $http) ->
  currentUser = 'n00b'


  # nowService.on 'notifyUser', (notify,newN)->
  #   console.log notify
  onlineUsers = {}
  noobs=0;

  nowService.on 'updatePageUser', (action, users) ->
    if action == 'replace'
       onlineUsers = {}
       noobs = 0; 

    # not obj if delete
    if action == 'delete'
      delete onlineUsers[users]
      if users == 'n00b'
        noobs--
    else
      for key, group of users
        for i, user of group
          if i == 'n00b'
            noobs++
          else if !onlineUsers[user]
            onlineUsers[user.name] = user
  
  on : nowService.on

  getOnlineUsers : ()->
    onlineUsers : onlineUsers
    noobs : noobs

  getCurrentUser : (callback)->
    now.ready ->
      now.currentUser (username) ->
        callback(username)









app.factory('userService', ($q, $rootScope, nowService, $filter)-> 
  page = 0
  number = 20
  data = []
  filter = 'created'
  user = null

  on : nowService.on

  updateUserPic : (user, url, callback)->
    now.ready ->
      now.updateUserPic user, url, (err)->
        callback(err)

  setBackground : (pageName,bg)->
    now.ready ->
      now.setProfileBackground pageName, bg, (err)->
        if err 
          alert(err)

  switchFilter : (_filter) ->
    filter = _filter
    page = 0
    data = []    

  getData : () ->
    data : data
    filter : filter
    user : user

  getUserData : (_user) ->
    deferred = $q.defer();
    now.ready ->
      now.loadUserProfile _user, (err,userData) ->
        $rootScope.$apply(deferred.resolve(userData))
    deferred.promise;

  getNextPage : (_user) ->
    if _user  != user
      user = _user
      page = 0
      data = []
    deferred = $q.defer();
    now.ready ->
      now.loadUserPages user, page, number,  filter, (err,result) ->
        page++;
        result = $filter('timeAgo')(result)
        # result = $filter('galleryThumb')(result)
        data = data.concat(result)
        $rootScope.$apply(deferred.resolve(data))
    deferred.promise;
)

app.factory  'pageCache', ()->
  pages=[]
  pageScroll=[]
  getPage : (pageName)->
     pages[pageName]
  savePage: (pageName, data)->
    pages[pageName] = data
  saveScroll : (pageName, scroll)->
    pageScroll[pageName] = scroll
  getScroll : (pageName)->
    pageScroll[pageName]


app.factory 'galleryService', ($q, $rootScope, nowService, $filter)-> 
  page = 0
  number = 40
  data = []
  filter = 'created'



  nowService.on 'updateMain', (page, action, filter)->
    if action == 'add'
      if filter == 'created' || filter == 'edited'
        data.unshift(page)
    if action == 'delete'
      for p, i in data
        if p.pageName == page 
          data.splice(i,1)
          return

 

  switchFilter : (_filter) ->
    filter = _filter
    page = 0
    data = []    

  getData : () ->
    data : data
    filter : filter


  getNextPage : () ->
    deferred = $q.defer();
    now.ready ->
      now.loadMainPage page, number, filter, (result) ->
        page++;
        result = $filter('timeAgo')(result)
        # result = $filter('galleryThumb')(result)
        data = data.concat(result)
        $rootScope.$apply(deferred.resolve(data))
    deferred.promise;


app.factory('feed', ($q, $rootScope, nowService)-> 
  
  page = 0
  number = 40
  data = []
  filter = ""

  on : nowService.on

  nowService.on "notifyFeed", (notify)->
    data = notify.concat(data)
    # console.log(notify)

  getData : ()->
    data

  getNextPage : ()->
    deferred = $q.defer();
    now.ready ->
      now.loadMainNotify page, number, filter, (result) ->
        page++
        $rootScope.$apply(deferred.resolve(result);)
        data = data.concat(result)
    deferred.promise;
)

app.factory('pageService', ($q, $rootScope, nowService)-> 

  on : nowService.on
  # now.newElement = (elArray)->
    # $rootScope.updateElement(elArray)

  likePage : (action, version, callback)->
    now.ready -> 
      now.likePage action, version, (err, action)->
        callback(err, action)


  setPrivacy : (pageName, privacy, editors, callback)->
    now.ready ->
      now.setPrivacy pageName, privacy, editors, (err)->
        callback(err)

  addPage : (desiredPageName, copyPage, callback)-> 
    now.ready ->
      now.addPage desiredPageName, copyPage, (err, newPage)->
        callback(err, newPage)

  deletePage : (pageName, callback)->
    now.ready ->
      now.deletePage pageName, (err)->
        callback(err)

  addNewImg : (pageName, elArray)->
    now.ready ->
      now.addNewImg pageName, elArray, (err)->
        if err 
          alert(err)

  setBackground : (pageName,bg)->
    now.ready ->
      now.setBackground pageName, bg, (err)->
        if err 
          alert(err)   

  getData : (pageName,userProfile,version)->
    permissins = 0

    now.updateFeed =(user, image, page, action) ->
      console.log (user) 
      console.log (image) 
      console.log (page)
      console.log (action) 


    now.setPagePermissions = (_pageName, _permissions) ->
      permissions = _permissions

    deferred = $q.defer();
    now.ready ->
      now.getPagePermissions pageName, userProfile, version, (err) ->
        if(!err)
          now.loadAll pageName, userProfile, version, (err,data) ->
            $rootScope.$apply(deferred.resolve(data);)
    deferred.promise;
)
