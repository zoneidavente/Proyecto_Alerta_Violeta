const test = require("node:test");
const assert = require("node:assert/strict");

const {
    buildNotificationDateFilter,
    getAccountCreatedAt
} = require("../utils/notificationDateFilter");
const notificationDateFilter = require("../middleware/notificationDateFilter");

test("leaves requests without notification scope unfiltered", async () => {
    const req = { query: {} };
    let nextCalled = false;
    const res = {
        status() {
            throw new Error("Unexpected response");
        },
        json() {
            throw new Error("Unexpected response");
        }
    };

    await notificationDateFilter(req, res, () => {
        nextCalled = true;
    });

    assert.equal(nextCalled, true);
    assert.deepEqual(req.notificationDateFilter, {});
});

test("includes the current and previous Colombia calendar days", () => {
    const now = new Date("2026-10-23T15:00:00.000Z");
    const filter = buildNotificationDateFilter(
        new Date("2026-10-20T12:00:00.000Z"),
        now
    );

    assert.deepEqual(filter, {
        fecha: {
            $gte: new Date("2026-10-22T05:00:00.000Z"),
            $lte: now
        }
    });
});

test("uses account creation as the lower limit when it is more recent", () => {
    const createdAt = new Date("2026-10-23T14:30:00.000Z");
    const filter = buildNotificationDateFilter(
        createdAt,
        new Date("2026-10-23T15:00:00.000Z")
    );

    assert.equal(filter.fecha.$gte.getTime(), createdAt.getTime());
});

test("retains support for existing accounts without createdAt", () => {
    const objectIdTimestamp = new Date("2026-10-21T18:00:00.000Z");
    const user = { _id: { getTimestamp: () => objectIdTimestamp } };

    assert.equal(getAccountCreatedAt(user), objectIdTimestamp);
});

test("fails explicitly when no account creation date is available", () => {
    assert.throws(
        () => getAccountCreatedAt({}),
        /No se pudo determinar la fecha de creación/
    );
});

test("rejects notifications dated in the future by setting now as the upper limit", () => {
    const now = new Date("2026-10-23T15:00:00.000Z");
    const filter = buildNotificationDateFilter(
        new Date("2026-10-22T05:00:00.000Z"),
        now
    );

    assert.equal(filter.fecha.$lte, now);
});
