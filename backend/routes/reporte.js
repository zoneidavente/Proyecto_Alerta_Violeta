const express = require("express");

const router = express.Router();

const Reporte = require("../models/Reporte");


// CREAR REPORTE
router.post("/reporte", async (req, res) => {

    console.log("BODY RECIBIDO:");
    console.log(req.body);

    try {

        const nuevoReporte = new Reporte({

            alias: req.body.alias,

            tipo_acoso: req.body.tipo_acoso,

            descripcion: req.body.descripcion,

            latitud: req.body.latitud,

            longitud: req.body.longitud,

            direccion: req.body.direccion,
        });

        await nuevoReporte.save();

        res.json({
            success: true,
            message: "Reporte guardado",
        });

    } catch (error) {

        console.log(error);

        res.status(500).json({
            success: false,
            message: error.message,
        });
    }
});


// OBTENER REPORTES
router.get("/reporte", async (req, res) => {

    try {

        const reportes = await Reporte.find()
            .sort({ fecha: -1 });

        res.json(reportes);

    } catch (error) {

        console.log(error);

        res.status(500).json({
            success: false,
            message: "Error al obtener reportes",
        });
    }
});


module.exports = router;