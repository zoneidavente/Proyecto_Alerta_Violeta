const crypto = require("crypto");

function hashSessionToken(token) {
    return crypto.createHash("sha256").update(token).digest("hex");
}

function getBearerToken(header) {
    if (typeof header !== "string") {
        return null;
    }

    const match = /^Bearer ([A-Za-z0-9]+)$/i.exec(header.trim());
    return match ? match[1] : null;
}

module.exports = { hashSessionToken, getBearerToken };
