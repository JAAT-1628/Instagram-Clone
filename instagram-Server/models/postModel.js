const mongoose = require('mongoose');
const Schema = mongoose.Schema;

// Post Schema
const PostSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  imageUrl: {
    type: String
  },
  videoUrl: {
    type: String
  },
  mediaType: {
    type: String,
    enum: ['image', 'video'],
    required: false
  },
  date: {
    type: Date,
    default: Date.now
  },
  likes: [{
    type: Schema.Types.ObjectId,
    ref: 'User',
    default: []
  }],
  caption: {
    type: String,
    default: ''
  },
  comments: [
    {
      userId: {
        type: Schema.Types.ObjectId,
        ref: 'User'
      },
      text: {
        type: String,
        required: true
      },
      date: {
        type: Date,
        default: Date.now
      }
    }
  ]
});


// Create model from schema
const Post = mongoose.model('Post', PostSchema);

module.exports = Post;