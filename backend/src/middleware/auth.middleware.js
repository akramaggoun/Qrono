const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
    // 1. Get token from header
    const token = req.header('Authorization')?.split(' ')[1];

    if (!token) {
        return res.status(401).json({ message: 'No token, authorization denied' });
    }

    try {
        // 2. Verify token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // 3. Attach payload (usually contains userId) to request
        // You'll use this later when the DB guy gives you the User model
        req.user = decoded; 
        
        next();
    } catch (err) {
        res.status(401).json({ message: 'Token is not valid' });
    }
};
