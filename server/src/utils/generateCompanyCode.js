/**
 * Generate a random, short, easy-to-remember company code
 * Format: 2 uppercase letters + 4 digits (e.g., AB1234)
 * @returns {string} 6-character company code
 */
const generateCompanyCode = () => {
  const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // Exclude I, O to avoid confusion
  const digits = '0123456789';

  let code = '';

  // 2 random uppercase letters
  for (let i = 0; i < 2; i++) {
    code += letters.charAt(Math.floor(Math.random() * letters.length));
  }

  // 4 random digits
  for (let i = 0; i < 4; i++) {
    code += digits.charAt(Math.floor(Math.random() * digits.length));
  }

  return code;
};

module.exports = generateCompanyCode;
