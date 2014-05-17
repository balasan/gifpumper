module.exports = (app, db, everyone) ->
  

  isUrl = (s) ->
    regexp = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/
    regexp.test s


  partials : (req, res) ->
    name = req.params.name;
    res.render('partials/' + name);
  
  partialsElements : (req, res) ->
    name = req.params.name;
    res.render('partials/elements/' + name);  


  index : (req, res, next) ->
    tokens = req.params[0].split("/")
    


    if tokens[0] is "public" or tokens[0] is "favicon.ico" or tokens[0] is "partials"
      next()
      return

    console.log('render index')

    res.render('index')
    # next()
    return false

    console.log('still')
    
    #console.log(req.params[0])
    pageName = tokens[0]
    console.log pageName
    
    pageName = "main"  if pageName is ""


    unless tokens[0] is "profile"
      db.pageModel.findOne
        pageName: pageName
      ,
        versions:
          $slice: 0
        text:
          $slice: -20
        notify:
          $slice: -100
      , (error, result) ->
          unless error
            img = undefined
            if result isnt `undefined` and result.backgroundImage isnt `undefined` and isUrl(result.backgroundImage)
              img = result.backgroundImage
            else if result isnt `undefined` and result.images isnt `undefined` and result.images[0] isnt `undefined` and result.images[0] isnt ""
              img = result.images[0].url
            else
              img = "http://asdf.us/im/16/recliningnude_02_1318746347_d_magik_1327306294_d_magik.gif"
            title = pageName
            url = "http://gifpumper.com/" + encodeURI(pageName)
            if pageName is "main"
              pageName = ""
              title = "gifpumper"
              url = "http://gifpumper.com"
              pagefilter = 'created'
            db.pageModel.find(
              privacy:
                $ne: 3
            ,
              pageName: 1
              likes: 1
              likesN: 1
              privacy: 1
              contributors: 1
              owner: 1
              vLikes: 1
              backgroundImage: 1
              "images.url": 1
              "images.oHeight": 1
              "images.oWidth": 1

              background: 1
              "versions.currentVersion": 1
            ).sort( "-"+pagefilter+" "+"pageName").limit(20).exec (err, result2) ->
              unless err
                res.render "index",
                  loggedIn: true
                  user: "n00b"
                  owner: false
                  privacy: 3
                  getPageData: result
                  image: img
                  title: title
                  url: url
                  pageData: result
                  pages: result2

                
    else
      console.log('render profile')
      res.render "index",
        loggedIn: true
        user: "n00b"
        owner: false
        privacy: 3
        getPageData: null
        image: ""
        title: "profile"
        url: "gifpumper.com"
