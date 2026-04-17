const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'fallback_qrono_secret_key_2024';
const QR_SECRET = process.env.QR_SECRET || 'fallback_qrono_qr_key_2024';

console.log('🔑 JWT Utility: Secrets initialized');

const generateUserToken = (payload) => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: '1d' });
};

const verifyUserToken = (token) => {
  return jwt.verify(token, JWT_SECRET);
};

const generateQrToken = (payload, expiresIn) => {
  return jwt.sign(payload, QR_SECRET, { expiresIn });
};

const verifyQrToken = (token) => {
  return jwt.verify(token, QR_SECRET);
};

module.exports = {
  generateUserToken,
  verifyUserToken,
  generateQrToken,
  verifyQrToken
};

