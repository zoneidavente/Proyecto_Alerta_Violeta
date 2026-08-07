const express = require("express");
const cors = require("cors");

const connectDB = require("./db");

const authRoutes = require("./routes/auth");

const reporteRoutes = require("./routes/reporte");

const emergenciaRoutes = require("./routes/emergencia");


const app = express();


// CONECTAR MONGODB
connectDB();


// MIDDLEWARES
app.use(cors());
app.use(express.json());


// RUTAS
app.use("/", authRoutes);
app.use("/", reporteRoutes);
app.use("/", emergenciaRoutes);

// SERVIDOR
app.listen(3000, "0.0.0.0", () => {

    console.log("Servidor corriendo en puerto 3000");

});