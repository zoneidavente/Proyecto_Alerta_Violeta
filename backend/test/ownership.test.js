const test = require("node:test");
const assert = require("node:assert/strict");
const crypto = require("node:crypto");
const express = require("express");

const authenticate = require("../middleware/authenticate");
const Session = require("../models/Session");
const User = require("../models/User");
const { getBearerToken, hashSessionToken } = require("../utils/sessionToken");
const { ownedRecordFilter } = require("../utils/recordOwnership");

test("extracts only a bearer token from the authorization header", () => {
    assert.equal(getBearerToken("Bearer abc123"), "abc123");
    assert.equal(getBearerToken("Basic abc123"), null);
    assert.equal(getBearerToken(undefined), null);
});

test("hashes session tokens before looking them up", () => {
    const token = "private-session-token";
    const expected = crypto.createHash("sha256").update(token).digest("hex");

    assert.equal(hashSessionToken(token), expected);
    assert.notEqual(hashSessionToken(token), token);
});

test("requires a valid bearer session and does not trust a request alias", async () => {
    const token = "a1b2c3";
    const sessionId = "507f1f77bcf86cd799439011";
    const originalFindOne = Session.findOne;
    const originalFindById = User.findById;
    let sessionQuery;
    let selectedFields;

    Session.findOne = async (query) => {
        sessionQuery = query;
        return { userId: sessionId };
    };
    User.findById = (id) => {
        assert.equal(id, sessionId);
        return {
            select: async (fields) => {
                selectedFields = fields;
                return {
                    _id: { toString: () => sessionId },
                    alias: "cuenta-verificada",
                    role: "usuario",
                    createdAt: new Date("2026-10-20T00:00:00.000Z"),
                };
            },
        };
    };

    const req = {
        get: (name) => name === "authorization" ? `Bearer ${token}` : null,
        body: { alias: "alias-falsificado" },
    };
    let nextCalled = false;
    const res = {
        status() {
            throw new Error("Unexpected response");
        },
        json() {
            throw new Error("Unexpected response");
        },
    };

    try {
        await authenticate(req, res, () => {
            nextCalled = true;
        });
    } finally {
        Session.findOne = originalFindOne;
        User.findById = originalFindById;
    }

    assert.equal(nextCalled, true);
    assert.equal(sessionQuery.tokenHash, hashSessionToken(token));
    assert.ok(sessionQuery.expiresAt.$gt instanceof Date);
    assert.equal(selectedFields, "alias role createdAt");
    assert.equal(req.auth.alias, "cuenta-verificada");
    assert.equal(req.auth.id, sessionId);
});

test("rejects requests without a bearer session", async () => {
    let statusCode;
    let responseBody;
    const res = {
        status(code) {
            statusCode = code;
            return this;
        },
        json(body) {
            responseBody = body;
        },
    };

    await authenticate({ get: () => null }, res, () => {
        throw new Error("Unauthenticated request must not continue");
    });

    assert.equal(statusCode, 401);
    assert.equal(responseBody.success, false);
});

test("targets updates and deletes using both record id and authenticated owner", () => {
    const id = "507f1f77bcf86cd799439012";
    const userId = "507f1f77bcf86cd799439013";

    assert.deepEqual(ownedRecordFilter(id, userId), {
        _id: id,
        owner: userId,
    });
});

test("restricts administrator-only operations by authenticated role", () => {
    let statusCode;
    const res = {
        status(code) {
            statusCode = code;
            return this;
        },
        json() {},
    };

    authenticate.requireAdministrator(
        { auth: { role: "usuario" } },
        res,
        () => {
            throw new Error("A regular user must not continue");
        }
    );
    assert.equal(statusCode, 403);

    let nextCalled = false;
    authenticate.requireAdministrator(
        { auth: { role: "administrador" } },
        res,
        () => {
            nextCalled = true;
        }
    );
    assert.equal(nextCalled, true);
});

test("rejects report edits and SOS deletion when records belong to another user", async () => {
    const Reporte = require("../models/Reporte");
    const Emergencia = require("../models/Emergencia");
    const reportId = "507f1f77bcf86cd799439014";
    const alertId = "507f1f77bcf86cd799439015";
    const ownerId = "507f1f77bcf86cd799439016";
    const token = "aabbccddeeff";
    const originalSessionFindOne = Session.findOne;
    const originalUserFindById = User.findById;
    const originalReportUpdate = Reporte.findOneAndUpdate;
    const originalEmergencyDelete = Emergencia.findOneAndDelete;
    const queries = [];

    Session.findOne = async (query) => {
        assert.equal(query.tokenHash, hashSessionToken(token));
        return { userId: ownerId };
    };
    User.findById = () => ({
        select: async () => ({
            _id: { toString: () => ownerId },
            alias: "solicitante",
            role: "usuario",
        }),
    });
    Reporte.findOneAndUpdate = async (filter) => {
        queries.push(filter);
        return null;
    };
    Emergencia.findOneAndDelete = async (filter) => {
        queries.push(filter);
        return null;
    };

    const app = express();
    app.use(express.json());
    app.use(require("../routes/reporte"));
    app.use(require("../routes/emergencia"));
    const server = app.listen(0, "127.0.0.1");

    try {
        await new Promise((resolve) => server.once("listening", resolve));
        const address = server.address();
        const baseUrl = `http://127.0.0.1:${address.port}`;
        const headers = {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
        };
        const reportResponse = await fetch(`${baseUrl}/reporte/${reportId}`, {
            method: "PUT",
            headers,
            body: JSON.stringify({ descripcion: "cambio no autorizado" }),
        });
        const alertResponse = await fetch(
            `${baseUrl}/emergencia/${alertId}`,
            { method: "DELETE", headers }
        );

        assert.equal(reportResponse.status, 404);
        assert.equal(alertResponse.status, 404);
        assert.deepEqual(queries, [
            { _id: reportId, owner: ownerId },
            { _id: alertId, owner: ownerId },
        ]);
    } finally {
        await new Promise((resolve, reject) => {
            server.close((error) => error ? reject(error) : resolve());
        });
        Session.findOne = originalSessionFindOne;
        User.findById = originalUserFindById;
        Reporte.findOneAndUpdate = originalReportUpdate;
        Emergencia.findOneAndDelete = originalEmergencyDelete;
    }
});
