const User = require("../models/User");
const {
    buildNotificationDateFilter,
    getAccountCreatedAt
} = require("../utils/notificationDateFilter");

async function notificationDateFilter(req, res, next) {
    if (req.query.scope !== "notifications") {
        req.notificationDateFilter = {};
        return next();
    }

    const alias = typeof req.query.alias === "string" ? req.query.alias.trim() : "";
    if (!alias) {
        return res.status(400).json({
            success: false,
            message: "Se requiere el alias para cargar las notificaciones."
        });
    }

    try {
        const user = await User.findOne({ alias }).select("createdAt");
        if (!user) {
            return res.status(404).json({
                success: false,
                message: "No se encontró la cuenta para filtrar las notificaciones."
            });
        }

        req.notificationDateFilter = buildNotificationDateFilter(
            getAccountCreatedAt(user)
        );
        return next();
    } catch (error) {
        console.error("Error al determinar el período de notificaciones:", error);
        return res.status(500).json({
            success: false,
            message: "No se pudo determinar el período de notificaciones."
        });
    }
}

module.exports = notificationDateFilter;
