const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const userSchema = new mongoose.Schema({
    alias: {
        type: String,
        required: true,
        unique: true
    },

    password: {
        type: String,
        required: true
    },

    recoveryCode: {
        type: String,
        required: true
    },

    createdAt: {
        type: Date,
        immutable: true
    },

    role: {
    type: String,
    enum: ["usuario", "administrador"],
    default: "usuario"
    }
});

userSchema.pre('save', async function () {
    if (!this.isModified('password')) {
        return;
    }

    const salt = await bcrypt.genSalt(10);

    this.password = await bcrypt.hash(
        this.password,
        salt
    );
});

module.exports = mongoose.model('User', userSchema);