const express = require("express");
const router = express.Router();

const User = require("../models/User");
const Session = require("../models/Session");
const bcrypt = require("bcrypt");
const crypto = require("crypto");
const { hashSessionToken } = require("../utils/sessionToken");

// LOGIN
router.post("/login", async (req, res) => {

    const { alias, password } = req.body;

    try {

        if (!alias || !password) {
            return res.json({
                success: false,
                message: "Datos incompletos",
            });
        }

        // BUSCAR USUARIO
        let user = await User.findOne({ alias });

        // SI NO EXISTE → NO PUEDE INICIAR SESIÓN
        if (!user) {
        return res.json({
        success: false,
        message: "El usuario no está registrado",
        });
        }
   

        // VALIDAR PASSWORD CON BCRYPT
        const passwordValida = await bcrypt.compare(
            password,
            user.password
        );

        if (passwordValida) {
            const token = crypto.randomBytes(32).toString("hex");
            const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
            await Session.create({
                userId: user._id,
                tokenHash: hashSessionToken(token),
                expiresAt,
            });

            return res.json({
                success: true,
                message: "Inicio de sesión exitoso",
                role: user.role,
                token,
            });

        } else {

            return res.json({
                success: false,
                message: "Contraseña incorrecta",
            });
        }

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});


// RECUPERAR CONTRASEÑA
router.post("/recuperar", async (req, res) => {

    const { alias, recoveryCode, password } = req.body;

    try {

        if (!alias || !recoveryCode || !password) {
            return res.json({
                success: false,
                message: "Datos incompletos",
            });
        }

        const user = await User.findOne({ alias });

        if (!user) {
            return res.json({
                success: false,
                message: "Datos de recuperación incorrectos",
            });
        }

        if (user.recoveryCode !== recoveryCode) {
            return res.json({
                success: false,
                message: "Clave de recuperación incorrecta",
            });
        }

        // Generar nueva clave de recuperación
        const newRecoveryCode = Math.floor(
            1000 + Math.random() * 9000
        ).toString();

        user.password = password;
        user.recoveryCode = newRecoveryCode;

        await user.save();

        return res.json({
            success: true,
            message: "Contraseña actualizada correctamente",
            recoveryCode: newRecoveryCode,
        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});

// VERIFICAR CLAVE DE RECUPERACIÓN
router.post("/verificar-recuperacion", async (req, res) => {

    const { alias, recoveryCode } = req.body;

    try {

        if (!alias || !recoveryCode) {
            return res.json({
                success: false,
                message: "Completa todos los campos",
            });
        }

        const user = await User.findOne({ alias });

        if (!user) {
            return res.json({
                success: false,
                message: "Datos de recuperación incorrectos",
            });
        }

        if (user.recoveryCode !== recoveryCode) {
            return res.json({
                success: false,
                message: "Clave de recuperación incorrecta",
            });
        }

        return res.json({
            success: true,
            message: "Clave de recuperación correcta",
        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});

// REGISTRAR USUARIO
router.post("/registrar", async (req, res) => {

    const { alias, password } = req.body;

    try {

        if (!alias || !password) {
            return res.json({
                success: false,
                message: "Datos incompletos",
            });
        }

        const usuarioExistente = await User.findOne({ alias });

        if (usuarioExistente) {
            return res.json({
                success: false,
                message: "El alias ya está registrado",
            });
        }

        const recoveryCode = Math.floor(
            1000 + Math.random() * 9000
        ).toString();

        const user = new User({
            alias,
            password,
            recoveryCode,
            createdAt: new Date(),
        });

        await user.save();

        return res.json({
            success: true,
            message: "Usuario creado correctamente",
            recoveryCode: recoveryCode,
        });

    } catch (error) {

        console.error(error);

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});
module.exports = router;