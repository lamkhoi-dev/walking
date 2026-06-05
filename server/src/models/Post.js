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
      enum: ['public', 'groups', 'friends'],
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
      enum: ['text', 'image', 'video', 'shared_post', 'shared_contest'],
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
        type: { type: String, enum: ['image', 'video'], default: 'image' },
        thumbnail: { type: String, default: null },
        duration: { type: Number, default: 0 },
      },
    ],
    mediaLayout: {
      type: String,
      enum: [
        null,
        // 2 images
        'two_side',        // side-by-side (default for 2)
        'two_stack',       // top-bottom stacked
        'two_left_large',  // left 2/3 + right 1/3
        'two_right_large', // left 1/3 + right 2/3
        // 3 images
        'three_left',      // left large + 2 stacked right (default for 3)
        'three_top',       // top large + 2 bottom row
        'three_cols',      // three equal columns
        'three_right_large', // 2 stacked left + right large
        // 4 images
        'four_grid',       // 2×2 grid (default for 4)
        'four_top_banner', // top large + 3 bottom row
        'four_left_large', // left large + 3 stacked right
        'four_right_large',// 3 stacked left + right large
      ],
      default: null,
    },

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

    // === EDIT TRACKING ===
    editedAt: {
      type: Date,
      default: null,
    },

    // === OFFICIAL & PIN ===
    isOfficial: {
      type: Boolean,
      default: false,
    },
    isPinned: {
      type: Boolean,
      default: false,
    },
    pinnedAt: {
      type: Date,
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
postSchema.index({ companyId: 1, isPinned: -1, pinnedAt: -1, createdAt: -1 });

postSchema.set('toJSON', {
  transform: (doc, ret) => {
    delete ret.__v;
    return ret;
  },
});

module.exports = mongoose.model('Post', postSchema);
