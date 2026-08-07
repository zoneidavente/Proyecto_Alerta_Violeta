const mongoose = require("mongoose");

const ReporteSchema = new mongoose.Schema({

    alias: {
        type: String,
        required: true,
    },

    tipo_acoso: {
        type: String,
        required: true,
    },

    descripcion: {
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

module.exports = mongoose.model("Reporte", ReporteSchema);