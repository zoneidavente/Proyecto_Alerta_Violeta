function ownedRecordFilter(id, userId) {
    return { _id: id, owner: userId };
}

module.exports = { ownedRecordFilter };
