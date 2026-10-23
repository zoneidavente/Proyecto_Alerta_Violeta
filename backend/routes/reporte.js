const express = require("express");
const mongoose = require("mongoose");

const router = express.Router();

const Reporte = require("../models/Reporte");
const Emergencia = require("../models/Emergencia");
const authenticate = require("../middleware/authenticate");
const { requireAdministrator } = authenticate;
const notificationDateFilter = require("../middleware/notificationDateFilter");
const { ownedRecordFilter } = require("../utils/recordOwnership");


// CREAR REPORTE
router.post("/reporte", authenticate, async (req, res) => {
    try {
        const nuevoReporte = new Reporte({
            owner: req.auth.id,
            alias: req.auth.alias,
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
router.get("/reporte", notificationDateFilter, async (req, res) => {

    try {

        const reportes = await Reporte.find(req.notificationDateFilter)
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

router.get("/mis-registros", authenticate, async (req, res) => {
    try {
        const [reportes, alertas] = await Promise.all([
            Reporte.find({ owner: req.auth.id }).sort({ fecha: -1 }),
            Emergencia.find({ owner: req.auth.id }).sort({ fecha: -1 }),
        ]);

        return res.json({ reportes, alertas });
    } catch (error) {
        console.error("Error al obtener los registros propios:", error);
        return res.status(500).json({
            success: false,
            message: "No se pudieron obtener tus reportes y alertas.",
        });
    }
});

router.put("/reporte/:id", authenticate, async (req, res) => {
    const { tipo_acoso, descripcion } = req.body;
    const cambios = {};

    if (tipo_acoso !== undefined) {
        if (typeof tipo_acoso !== "string" || !tipo_acoso.trim()) {
            return res.status(400).json({
                success: false,
                message: "El tipo de acoso no es válido.",
            });
        }
        cambios.tipo_acoso = tipo_acoso.trim();
    }

    if (descripcion !== undefined) {
        if (typeof descripcion !== "string" || !descripcion.trim()) {
            return res.status(400).json({
                success: false,
                message: "La descripción no puede estar vacía.",
            });
        }
        cambios.descripcion = descripcion.trim();
    }

    if (Object.keys(cambios).length === 0) {
        return res.status(400).json({
            success: false,
            message: "No se proporcionaron cambios válidos.",
        });
    }

    if (!mongoose.isValidObjectId(req.params.id)) {
        return res.status(404).json({
            success: false,
            message: "Reporte no encontrado.",
        });
    }

    try {
        const reporte = await Reporte.findOneAndUpdate(
            ownedRecordFilter(req.params.id, req.auth.id),
            { $set: cambios },
            { new: true, runValidators: true }
        );
        if (!reporte) {
            return res.status(404).json({
                success: false,
                message: "Reporte no encontrado.",
            });
        }

        return res.json({
            success: true,
            message: "Reporte actualizado.",
            reporte,
        });
    } catch (error) {
        console.error("Error al actualizar un reporte propio:", error);
        res.status(500).json({
            success: false,
            message: "No se pudo actualizar el reporte.",
        });
    }
});

router.delete("/reporte/:id", authenticate, async (req, res) => {
    if (!mongoose.isValidObjectId(req.params.id)) {
        return res.status(404).json({
            success: false,
            message: "Reporte no encontrado.",
        });
    }

    try {
        const reporte = await Reporte.findOneAndDelete(
            ownedRecordFilter(req.params.id, req.auth.id)
        );
        if (!reporte) {
            return res.status(404).json({
                success: false,
                message: "Reporte no encontrado.",
            });
        }
        return res.json({ success: true, message: "Reporte eliminado." });
    } catch (error) {
        console.error("Error al eliminar un reporte propio:", error);
        return res.status(500).json({
            success: false,
            message: "No se pudo eliminar el reporte.",
        });
    }
});

router.put(
    "/reporte/:id/estado",
    authenticate,
    requireAdministrator,
    async (req, res) => {
        try {
            const reporteActualizado = await Reporte.findByIdAndUpdate(
                req.params.id,
                { estado: req.body.estado },
                { new: true, runValidators: true }
            );

            if (!reporteActualizado) {
                return res.status(404).json({
                    success: false,
                    message: "Reporte no encontrado",
                });
            }

            return res.json({
                success: true,
                message: "Estado actualizado",
                reporte: reporteActualizado,
            });
        } catch (error) {
            console.error("Error al actualizar el estado del reporte:", error);
            return res.status(500).json({
                success: false,
                message: "Error al actualizar el estado",
            });
        }
    }
);

module.exports = router;