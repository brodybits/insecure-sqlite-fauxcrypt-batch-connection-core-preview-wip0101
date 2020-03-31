function openDatabaseConnection (filename, flags, key, cb, errorCallback) {
  cordova.exec(cb, errorCallback, 'SQLiteDemo', 'openDatabaseConnection', [
    filename,
    flags,
    key
  ])
}

function executeBatch (connectionId, batchList, cb) {
  cordova.exec(cb, null, 'SQLiteDemo', 'executeBatch', [
    connectionId,
    batchList
  ])
}

window.openDatabaseConnection = openDatabaseConnection

window.executeBatch = executeBatch
