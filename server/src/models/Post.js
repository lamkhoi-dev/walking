const mongoose = require('mongoose');

const postSchema = new mongoose.Schema(
  {
    authorId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    companyId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Company',
      default: null,
    },

    // === VISIBILITY ===
    visibility: {
      type: String,
      enum: ['public', 'groups'],
      default: 'public',
    },
    visibleToGroups: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Group',
      },
    ],

    // === CONTENT ===
    type: {
      type: String,
      enum: ['text', 'image', 'shared_post', 'shared_contest'],
      default: 'text',
    },
    content: {
      type: String,
      trim: true,
      maxlength: 2000,
      default: '',
    },
    media: [
      {
        url: { type: String, required: true },
        publicId: { type: String, default: null },
        width: { type: Number, default: 0 },
        height: { type: Number, default: 0 },
      },
    ],

    // === SHARE ===
    sharedPostId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Post',
      default: null,
    },
    sharedContestId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Contest',
      default: null,
    },
    achievementRank: {
      type: Number,
      default: null,
    },
    achievementSteps: {
      type: Number,
      default: null,
    },

    // === COUNTERS (cached for performance) ===
    likesCount: {
      type: Number,
      default: 0,
    },
    commentsCount: {
      type: Number,
      default: 0,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for feed queries
postSchema.index({ visibility: 1, createdAt: -1 });
postSchema.index({ visibleToGroups: 1, createdAt: -1 });
postSchema.index({ companyId: 1, createdAt: -1 });
postSchema.index({ authorId: 1, createdAt: -1 });

postSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Post', postSchema);
