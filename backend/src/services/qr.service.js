const { generateQrToken, verifyQrToken } = require('../utils/jwt');

const createQrToken = (sessionId, validUntil) => {
  const now = new Date();
  const timeDiffMs = validUntil.getTime() - now.getTime();

  if (timeDiffMs <= 0) {
    throw new Error("Cannot generate QR: Time window expired");
  }

  const expiresInSeconds = Math.floor(timeDiffMs / 1000);

  const payload = {
    sessionId: sessionId
  };

  return generateQrToken(payload, `${expiresInSeconds}s`);
};

const validateQrToken = (token) => {
  try {
    return verifyQrToken(token);
  } catch (err) {
    throw new Error(`Invalid QR Code: ${err.message}`);
  }
};

module.exports = {
  createQrToken,
  validateQrToken
};
