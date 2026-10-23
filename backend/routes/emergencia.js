const express = require("express");
const router = express.Router();

const Emergencia = require("../models/Emergencia");
const mongoose = require("mongoose");
const authenticate = require("../middleware/authenticate");
const { requireAdministrator } = authenticate;
const notificationDateFilter = require("../middleware/notificationDateFilter");
const { ownedRecordFilter } = require("../utils/recordOwnership");

// GUARDAR ALERTA SOS
router.post("/emergencia", authenticate, async(req,res)=>{

    try{

        const nuevaEmergencia =
            new Emergencia({

            owner: req.auth.id,
            alias:req.auth.alias,
            latitud:req.body.latitud,
            longitud:req.body.longitud,
            direccion:req.body.direccion,
        });

        await nuevaEmergencia.save();

        res.json({

            success:true,
            message:"Alerta enviada"
        });

    }catch(error){

        console.log(error);

        res.status(500).json({

            success:false,
            message:error.message
        });
    }

});


// OBTENER ALERTAS
router.get("/emergencia", notificationDateFilter, async(req,res)=>{

    try{

        const alertas =
            await Emergencia.find(req.notificationDateFilter)
            .sort({fecha:-1});

        res.json(alertas);

    }catch(error){

        console.log(error);

        res.status(500).json({

            success:false,
            message:"Error al obtener alertas"
        });

    }

});

// ACTUALIZAR ESTADO DE LA ALERTA SOS
router.put(
    "/emergencia/:id/estado",
    authenticate,
    requireAdministrator,
    async (req, res) => {
        try {
            const emergenciaActualizada = await Emergencia.findByIdAndUpdate(
                req.params.id,
                { estado: req.body.estado },
                { new: true, runValidators: true }
            );

            if (!emergenciaActualizada) {
                return res.status(404).json({
                    success: false,
                    message: "Alerta SOS no encontrada",
                });
            }

            return res.json({
                success: true,
                message: "Estado de la alerta SOS actualizado",
                emergencia: emergenciaActualizada,
            });
        } catch (error) {
            console.error("Error al actualizar el estado de la alerta SOS:", error);
            return res.status(500).json({
                success: false,
                message: "Error al actualizar el estado de la alerta SOS",
            });
        }
    }
);

router.delete("/emergencia/:id", authenticate, async (req, res) => {
    if (!mongoose.isValidObjectId(req.params.id)) {
        return res.status(404).json({
            success: false,
            message: "Alerta SOS no encontrada.",
        });
    }

    try {
        const emergencia = await Emergencia.findOneAndDelete(
            ownedRecordFilter(req.params.id, req.auth.id)
        );
        if (!emergencia) {
            return res.status(404).json({
                success: false,
                message: "Alerta SOS no encontrada.",
            });
        }
        return res.json({
            success: true,
            message: "Alerta SOS eliminada.",
        });
    } catch (error) {
        console.error("Error al eliminar una alerta SOS propia:", error);
        return res.status(500).json({
            success: false,
            message: "No se pudo eliminar la alerta SOS.",
        });
    }
});

module.exports = router;