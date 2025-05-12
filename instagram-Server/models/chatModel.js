const mongoose = require('mongoose');

const chatSchema = new mongoose.Schema({
  participants: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  }],
  lastMessage: {
    type: String,
    default: ''
  },
  lastMessageAt: {
    type: Date,
    default: Date.now
  },
  unreadCount: {
    type: Map,
    of: Number,
    default: () => new Map()
  }
}, { timestamps: true });

// Drop existing indexes to avoid conflicts
chatSchema.pre('save', async function(next) {
  try {
    // Sort participants to ensure consistent ordering
    if (this.participants && Array.isArray(this.participants)) {
      this.participants.sort((a, b) => a.toString().localeCompare(b.toString()));
    }

    // Initialize unreadCount if it's empty
    if (!this.unreadCount || this.unreadCount.size === 0) {
      this.unreadCount = new Map(
        this.participants.map(p => [p.toString(), 0])
      );
    }

    next();
  } catch (error) {
    next(error);
  }
});

// Drop any existing indexes
chatSchema.pre('save', async function(next) {
  try {
    await this.constructor.collection.dropIndexes();
    next();
  } catch (error) {
    next();
  }
});

// Create a compound index for unique participant pairs
chatSchema.index(
  { 'participants.0': 1, 'participants.1': 1 },
  {
    unique: true,
    partialFilterExpression: {
      'participants.0': { $exists: true },
      'participants.1': { $exists: true }
    }
  }
);

// Index for efficient chat listing
chatSchema.index({ lastMessageAt: -1 });

// Format to match Swift decoding expectations
chatSchema.set('toJSON', {
  virtuals: true,
  transform: (doc, ret) => {
    // Ensure _id is a string
    ret._id = ret._id.toString();
    ret.id = ret._id;
    
    // Handle participants
    if (ret.participants && Array.isArray(ret.participants)) {
      ret.participants = ret.participants.map(p => {
        if (typeof p === 'object' && p !== null) {
          p._id = p._id.toString();
          p.id = p._id;
          return p;
        }
        return p.toString();
      });
    }
    
    // Convert unreadCount Map to object
    if (ret.unreadCount instanceof Map) {
      ret.unreadCount = Object.fromEntries(ret.unreadCount);
    } else if (ret.unreadCount && typeof ret.unreadCount === 'object') {
      // Ensure all keys are strings and values are numbers
      ret.unreadCount = Object.fromEntries(
        Object.entries(ret.unreadCount).map(([k, v]) => [
          k.toString(),
          Number(v) || 0
        ])
      );
    } else {
      ret.unreadCount = {};
    }
    
    // Format dates
    if (ret.lastMessageAt) {
      ret.lastMessageAt = ret.lastMessageAt.toISOString();
    }
    if (ret.createdAt) {
      ret.createdAt = ret.createdAt.toISOString();
    }
    if (ret.updatedAt) {
      ret.updatedAt = ret.updatedAt.toISOString();
    }
    
    delete ret.__v;
    return ret;
  }
});

module.exports = mongoose.model('Chat', chatSchema); 