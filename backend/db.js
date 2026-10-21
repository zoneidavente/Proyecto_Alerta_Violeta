
const mongoose = require("mongoose");

const connectDB = async () => {
    try {
        const uri = process.env.MONGODB_URI;

        if (!uri) {
            throw new Error("Falta configurar MONGODB_URI");
        }

        await mongoose.connect(uri);

        console.log("MongoDB Atlas conectado correctamente");

    } catch (error) {
        console.error("Error al conectar con MongoDB:", error.message);
        process.exit(1);
    }
};

module.exports = connectDB;
