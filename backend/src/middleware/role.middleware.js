const authorize = (req, res, next) => {
    const { role } = req.user; // Set by auth.middleware
    const { method, originalUrl } = req;

    // Logic: Only Professors can POST/DELETE to sessions
    if (originalUrl.includes('/sessions') && (method === 'POST' || method === 'DELETE')) {
        if (role !== 'PROFESSOR') {
            return res.status(403).json({ message: "Only Professors can manage sessions." });
        }
    }

    // Logic: Everyone (Students & Professors) can GET sessions
    next();
};

module.exports = authorize;
