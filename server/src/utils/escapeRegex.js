/**
 * Escape special regex characters in a string to prevent regex injection
 * @param {string} str - The string to escape
 * @returns {string} The escaped string safe for use in RegExp
 */
const escapeRegex = (str) => {
  return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
};

module.exports = escapeRegex;
