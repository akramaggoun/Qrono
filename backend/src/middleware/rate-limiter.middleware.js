const rateLimit = require('express-rate-limit');

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 mins
  max: 100, // Limit each IP to 100 requests per window (15 mins)
  message: {
    message: "Too many requests from this IP, please try again after 15 minutes"
  },
  standardHeaders: true, 
  legacyHeaders: false,
});

module.exports = globalLimiter;
