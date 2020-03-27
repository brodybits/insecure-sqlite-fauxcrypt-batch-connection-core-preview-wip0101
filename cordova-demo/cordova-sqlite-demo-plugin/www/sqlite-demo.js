function openDatabaseConnection (filename, flags, key, cb) {
  cordova.exec(cb, null, 'SQLiteDemo', 'openDatabaseConnection', [
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
