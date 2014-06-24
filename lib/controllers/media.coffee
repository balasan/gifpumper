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


  uploadToS3 = (url, callback)->
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

        date = new Date()
        path = date.getFullYear() + "/" + (date.getMonth() + 1) + '/'+ uniqueId() + filename
        console.log(path)
        s3.putObject 
          Body: body
          Key: path
          ContentType: contentType
          Bucket: process.env.bucket
          ACL: 'public-read'
        , (error, data) ->
          if error?
            console.log "error downloading image to s3: "
            console.log error
            callback(error)
          else 
            console.log "success uploading to s3"
            callback(null, "https://s3.amazonaws.com/gifpumper-images/" + path)


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

    media = uploadQue[0]
    if media
      queInProgress = true
      uploadToS3 media.sourceUrl, (err, localUrl)->
        # if media.pageId
        console.log "uploaded file to: "+ localUrl
        pageModel.find
          'images.url' : media.sourceUrl
        , (err, pages)->
          if !err
            for page in pages 
              for image in page.images
                if image.url == media.sourceUrl
                  image.url = localUrl
                  page.save()
                    # carefull here? closure problem
                  nowjs.getGroup(page._id).now.updateElement [image], {url:true}
                  console.log "updated image in " + page.pageName
              
            mediaModel.update
              _id : media.id
            ,
              $set :
                localUrl : localUrl
            , (err)->
              if err
                console.log (err)
              else
                console.log "processed que element"
                uploadQue.splice(0,1)
                queInProgress=false;
                console.log uploadQue.length + " left in que"
                processQue()
 

      # uploadToS3 img.url, (err, localUrl)->
      #   if !err 
      #     pageModel.update
      #       'images.url': img.url
      #     ,
      #       $set: 
      #         'images.$.url': localUrl,
      #     , (err)


  startQue()



               

  addToMedia : (img, pageId, userId, options, callback) ->
    local =false
    if img.contentType == "image"  
      if !img.url.match('https://gifpumper-images.s3.amazonaws.com/')
        local=false
      else
        local=true
        
      mediaModel.findOne
        sourceUrl : img.url
      , (err, media)->
        if err then console.log err

        updatePage = (img,pageId,mediaId)->
          pageModel.update
            _id : pageId
            'images._id' : img.id
          ,
            $set: 
              'images.$.mediaId': mediaId
          , (err) ->
            if !err 
              console.log "updated page img mediaID"
              nowjs.getGroup(pageId).now.updateElement [img],  {url:true}


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


        if media
          console.log 'media entry exists'
          console.log media
          if media.localUrl
            img.url = media.localUrl
          updatePage(img,pageId,media.id)
          if options && options.upload
            updateUserUploads(media.id,userId)
          
          callback(img, media.id)


        else
          media = new mediaModel
          if options && options.upload
            media.uploadedBy = userId
          media.sourceUrl = img.url
          if local 
            media.localUrl = img.url
          media.save (err)->
            console.log 'created media entry'
            console.log media
            # updatePage(img,pageId,media.id)
            callback(img, media.id)

            if options && options.upload
              updateUserUploads(media.id,userId)
              console.log "new upload"
            
            if !local
              # upload to S3 que
              media.pageId = pageId
              uploadQue.push media
              processQue()
  




