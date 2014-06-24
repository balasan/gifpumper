mongoose = require('mongoose')
Schema = mongoose.Schema


mediaSchema = new Schema
  localUrl : String
  sourceUrl : String
  uploadedBy:  
    type: Schema.Types.ObjectId
    ref: 'userModel'
  date: 
    type: Date 
    default: Date.now

mediaModel : mongoose.model("mediaModel", mediaSchema)


