const Session = require("../models/Session");
const User = require("../models/User");
const { getBearerToken, hashSessionToken } = require("../utils/sessionToken");

async function authenticate(req, res, next) {
    const token = getBearerToken(req.get("authorization"));
    if (!token) {
        return res.status(401).json({
            success: false,
            message: "Debes iniciar sesión para realizar esta acción.",
        });
    }

    try {
        const session = await Session.findOne({
            tokenHash: hashSessionToken(token),
            expiresAt: { $gt: new Date() },
        });
        if (!session) {
            return res.status(401).json({
                success: false,
                message: "La sesión no es válida o ha expirado.",
            });
        }

        const user = await User.findById(session.userId).select(
            "alias role createdAt"
        );
        if (!user) {
            return res.status(401).json({
                success: false,
                message: "La cuenta asociada a esta sesión ya no existe.",
            });
        }

        req.auth = {
            id: user._id.toString(),
            alias: user.alias,
            role: user.role,
            createdAt: user.createdAt,
        };
        return next();
    } catch (error) {
        console.error("Error al validar la sesión:", error);
        return res.status(500).json({
            success: false,
            message: "No se pudo validar la sesión.",
        });
    }
}

function requireAdministrator(req, res, next) {
    if (req.auth?.role !== "administrador") {
        return res.status(403).json({
            success: false,
            message: "Esta acción requiere una cuenta administradora.",
        });
    }
    return next();
}

module.exports = authenticate;
module.exports.requireAdministrator = requireAdministrator;
