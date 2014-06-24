mongoose = require('mongoose')
Schema = mongoose.Schema

toLower = (v) ->
  v.toLowerCase()

imageSchema = new Schema(
  width: String
  height: String
  oHeight: Number
  oWidth: Number
  top: String
  left: String
  anglex: Number
  angley: Number
  angler: Number
  z: Number
  url:
    type: String
  backgroundColor: String
  backgroundImage: String
  backgroundType: String
  content: String
  contentType: String
  opacity: Number
  user: String
  d2d:
    type: Boolean
    default: false
  mediaId:
    type: Schema.Types.ObjectId
    ref: 'mediaModel'
)

divSchema = new Schema(
  width: String
  height: String
  top: String
  left: String
  anglex: Number
  angley: Number
  angler: Number
  z: Number
  backgroundColor: String
  backgroundImage: String
  backgroundType: String
  content: String
  opacity: Number
  user: String
)

versionSchema = new Schema(
  pageName: String
  owner: String
  images: [imageSchema]
  backgroundImageType: Number
  background: String
  backgroundImage: String
  text: [textSchema]
  contributors: []
  likes: []
  likesN:
    type: Number
    default: 0
    min: 0
)

pageSchema = new Schema(
  pageName:
    type: String
    index:
      unique: true

  owner: String
  editors: []
  images: [imageSchema]
  privacy: Number
  backgroundImageType: Number
  background: String
  backgroundImage: String
  text: [textSchema]
  contributors: []
  parent: String
  children: []
  versions: [versionSchema]
  currentVersion:
    type: Number
    default: 0
    min: 0

  likes: []
  likesN:
    type: Number
    default: 0
    min: 0

  vLikes:
    type: Number
    default: 0
    min: 0

  d2d:
    type: Boolean
    default: false

  notify: [notifySchema]
  bgDisplay: String
  created:
    type: Date
    default: Date.now

  edited:
    type: Date
    default: Date.now
)

notifySchema = new Schema(
  user: String
  userObj:  { type: Schema.Types.ObjectId, ref: 'userModel', index: true }
  page: String
  pageObj:  { type: Schema.Types.ObjectId, ref: 'pageModel'}
  action: String
  version: Number
  time:
    type: Date
    default: Date.now
    index: true
  img: String
)

textSchema = new Schema(
  user: String
  text: String
  time:
    type: Date
    default: Date.now

  at: []
  hash: []
)

onlineSchema = new Schema(
  user: String
  page: { type: Schema.Types.ObjectId, ref: 'pageModel' }
  nowId:
    type: String
    index: true
)



pageModel : mongoose.model("pageModel", pageSchema)
imageModel : mongoose.model("imageModel", imageSchema)
textModel : mongoose.model("textModel", textSchema)
versionModel : mongoose.model("versionModel", versionSchema)
notifyModel : mongoose.model("notifyModel", notifySchema)
onlineModel : mongoose.model("onlineModel", onlineSchema)





