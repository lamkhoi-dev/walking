// ===== USER ROLES =====
const ROLES = {
  SUPER_ADMIN: 'super_admin',
  COMPANY_ADMIN: 'company_admin',
  MEMBER: 'member',
};

// ===== COMPANY STATUS =====
const COMPANY_STATUS = {
  PENDING: 'pending',
  APPROVED: 'approved',
  REJECTED: 'rejected',
  SUSPENDED: 'suspended',
};

// ===== MESSAGE TYPES =====
const MESSAGE_TYPES = {
  TEXT: 'text',
  IMAGE: 'image',
  SYSTEM: 'system',
};

// ===== CONVERSATION TYPES =====
const CONVERSATION_TYPES = {
  GROUP: 'group',
  DIRECT: 'direct',
};

// ===== CONTEST STATUS =====
const CONTEST_STATUS = {
  UPCOMING: 'upcoming',
  ACTIVE: 'active',
  COMPLETED: 'completed',
  CANCELLED: 'cancelled',
};

// ===== PAGINATION =====
const PAGINATION = {
  DEFAULT_PAGE: 1,
  DEFAULT_LIMIT: 20,
  MAX_LIMIT: 100,
};

// ===== RATE LIMIT =====
const RATE_LIMIT = {
  WINDOW_MS: 15 * 60 * 1000, // 15 minutes
  MAX_REQUESTS: 100,
  AUTH_WINDOW_MS: 15 * 60 * 1000,
  AUTH_MAX_REQUESTS: 20,
};

module.exports = {
  ROLES,
  COMPANY_STATUS,
  MESSAGE_TYPES,
  CONVERSATION_TYPES,
  CONTEST_STATUS,
  PAGINATION,
  RATE_LIMIT,
};
