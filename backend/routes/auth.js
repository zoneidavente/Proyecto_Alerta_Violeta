const express = require("express");
const router = express.Router();

const User = require("../models/User");


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

        // SI NO EXISTE → CREARLO
        if (!user) {

            user = new User({
                alias,
                password,
            });

            await user.save();

            return res.json({
                success: true,
                message: "Usuario creado y logueado",
            });
        }

        // VALIDAR PASSWORD
        if (user.password === password) {

            return res.json({
                success: true,
                message: "Login correcto",
            });

        } else {

            return res.json({
                success: false,
                message: "Contraseña incorrecta",
            });
        }

    } catch (error) {

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});

// RECUPERAR CONTRASEÑA
router.post("/recuperar", async (req, res) => {

    const { alias, password } = req.body;

    try {

        if (!alias || !password) {
            return res.json({
                success: false,
                message: "Datos incompletos",
            });
        }

        // BUSCAR USUARIO
        const user = await User.findOne({ alias });

        if (!user) {
            return res.json({
                success: false,
                message: "Usuario no existe",
            });
        }

        // ACTUALIZAR CONTRASEÑA
        user.password = password;

        await user.save();

        return res.json({
            success: true,
            message: "Contraseña actualizada correctamente",
        });

    } catch (error) {

        return res.status(500).json({
            success: false,
            message: "Error del servidor",
        });
    }
});
module.exports = router;