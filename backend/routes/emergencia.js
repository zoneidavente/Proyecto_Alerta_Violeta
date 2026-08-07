const express = require("express");
const router = express.Router();

const Emergencia = require("../models/Emergencia");

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
router.get("/emergencia", async(req,res)=>{

    try{

        const alertas =
            await Emergencia.find()
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

module.exports = router;