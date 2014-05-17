module.exports = (app, db, everyone) ->

  crypto = require('crypto');
  hash = (msg, key) ->
    crypto.createHmac("sha256", key).update(msg).digest "hex"


  authenticate = (name, pass, fn) ->
    db.userModel.findOne
      username: name
    , (err, user) ->
      
      # console.log(user.password)
      # console.log(hash(pass, user.salt))

      # if user.password is hash(pass, user.salt)
      #   console.log('yes!!!')
      # query the db for the given username
      return fn(new Error("cannot find user"))  if err or not user
      
      # apply the same algorithm to the POSTed password, applying
      # the hash against the pass / salt, if there is a match we
      # found the user

      return fn(null, user)  if user.password.toString() is hash(pass, user.salt)


      # Otherwise password is invalid
      fn new Error("invalid password")



  login : (req, res) ->
    if req.body.logout
      req.session.destroy ->
        res.redirect "/"

    if req.body.login
      authenticate req.body.username, req.body.password, (err, user) ->
        console.log(user)
        if user
          
          # Regenerate session when signing in
          # to prevent fixation 
          req.session.regenerate ->
            console.log(req.session)
            # Store the user's primary key 
            # in the session store to be retrieved,
            # or in this case the entire user object
            req.session.user = user.username
            res.redirect "/"

        else
          console.log('wrong pass')
          req.session.error = "Authentication failed, please check your " + " username and password." + " (use \"tj\" and \"foobar\")"
          res.redirect "back"

