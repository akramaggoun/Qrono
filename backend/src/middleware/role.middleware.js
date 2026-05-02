const checkRole = (allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Unauthorized: No user context found' });
    }

    const userRole = req.user.role;

    if (!allowedRoles.includes(userRole)) {
      return res.status(403).json({ 
        message: `Access denied: Required roles [${allowedRoles.join(', ')}], but user has role '${userRole}'` 
      });
    }

    next();
  };
};

module.exports = { checkRole };
