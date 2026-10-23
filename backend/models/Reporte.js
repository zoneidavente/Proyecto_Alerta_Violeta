const mongoose = require("mongoose");

const ReporteSchema = new mongoose.Schema({

    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "User",
        immutable: true,
        index: true,
    },

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

    estado: {
    type: String,
    enum: ["Pendiente", "En revisión", "Atendido", "Cerrado"],
    default: "Pendiente",
    },

    fecha: {
        type: Date,
        default: Date.now,
    },
});

module.exports = mongoose.model("Reporte", ReporteSchema);