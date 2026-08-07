const mongoose = require("mongoose");

const EmergenciaSchema = new mongoose.Schema({

    alias: {
        type: String,
        required: true,
    },

    latitud: {
        type: Number,
    },

    longitud: {
        type: Number,
    },

    direccion: {
        type: String,
    },

    fecha: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model(
    "Emergencia",
    EmergenciaSchema
);