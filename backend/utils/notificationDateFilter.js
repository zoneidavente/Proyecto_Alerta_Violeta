const COLOMBIA_OFFSET_MS = 5 * 60 * 60 * 1000;

function getAccountCreatedAt(user) {
    if (user.createdAt) {
        const createdAt = new Date(user.createdAt);
        if (Number.isFinite(createdAt.getTime())) {
            return createdAt;
        }
    }

    if (typeof user._id?.getTimestamp === "function") {
        return user._id.getTimestamp();
    }

    throw new Error("No se pudo determinar la fecha de creación de la cuenta.");
}

function buildNotificationDateFilter(accountCreatedAt, now = new Date()) {
    const createdAt = new Date(accountCreatedAt);
    if (!Number.isFinite(createdAt.getTime()) || !Number.isFinite(now.getTime())) {
        throw new Error("La fecha de creación o la fecha actual no es válida.");
    }

    const colombiaNow = new Date(now.getTime() - COLOMBIA_OFFSET_MS);
    const startOfYesterdayUtc = new Date(Date.UTC(
        colombiaNow.getUTCFullYear(),
        colombiaNow.getUTCMonth(),
        colombiaNow.getUTCDate() - 1,
        5
    ));
    const start = new Date(Math.max(startOfYesterdayUtc.getTime(), createdAt.getTime()));

    return {
        fecha: {
            $gte: start,
            $lte: now
        }
    };
}

module.exports = { buildNotificationDateFilter, getAccountCreatedAt };
