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

app.get("/health", (_req, res) => {
    res.json({ status: "ok" });
});

// RUTAS
app.use("/", authRoutes);
app.use("/", reporteRoutes);
app.use("/", emergenciaRoutes);

// SERVIDOR
const port = process.env.PORT || 3000;

app.listen(port, "0.0.0.0", () => {

    console.log(`Servidor corriendo en puerto ${port}`);

});