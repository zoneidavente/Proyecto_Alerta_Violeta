const express = require("express");
const router = express.Router();

const Emergencia = require("../models/Emergencia");
const notificationDateFilter = require("../middleware/notificationDateFilter");

// GUARDAR ALERTA SOS
router.post("/emergencia", async(req,res)=>{

    try{

        const nuevaEmergencia =
            new Emergencia({

            alias:req.body.alias,
            descripcion:req.body.descripcion,
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
router.put("/emergencia/:id/estado", async (req, res) => {
    try {
        const emergenciaActualizada = await Emergencia.findByIdAndUpdate(
            req.params.id,
            {
                estado: req.body.estado
            },
            { new: true }
        );

        if (!emergenciaActualizada) {
            return res.status(404).json({
                success: false,
                message: "Alerta SOS no encontrada"
            });
        }

        res.json({
            success: true,
            message: "Estado de la alerta SOS actualizado",
            emergencia: emergenciaActualizada
        });

    } catch (error) {
        console.log(error);

        res.status(500).json({
            success: false,
            message: "Error al actualizar el estado de la alerta SOS"
        });
    }
});

module.exports = router;