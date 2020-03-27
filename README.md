# SQLite batch connection support preview 2020-01

**Author:** Christopher J. Brody <mailto:chris.brody+brodybits@gmail.com>

**LICENSE:** MIT with commercial license option

Low-level SQLite connection library for C, C++, Objective-C, and Java

to support SQLite batch processing in higher-level app frameworks such as Apache Cordova

with demonstration of use in an extremely simple Cordova plugin for mobile apps in JavaScript

designed to be thread-safe

with support available here: <https://github.com/brodybits/ask-me-anything/issues>

## Contents

- `sqlite-connection-core.h` - main low-level C API header
- `sqlite-connection-core.c` - main low-level C library source module
- `ctest` - test of main low-level C library
- `sccglue` - low-level Java API wrapper generated with help from GlueGen from jogamp.org, with JNI test
- `cordova-demo` - extremely simple Cordova demo app for testing, reformatted by `prettier-standard`, includes Cordova demo plugin:
  - `cordova-sqlite-demo-plugin` - extremely simple Cordova plugin that can open a SQLite database, execute a set of batch statements with parameters, and send the results to the Cordova JavaScript app
- with some other top-level Makefile artifacts included

## Major features

- API designed to work with integer connection ID that is easy to use from C API or Java wrapper generated by GlueGen
- able to bind 64-bit integer, double-precision float, text string, or null values to SQL statemeents with `?` placeholders
- able to retrieve one or multiple rows of results with 64-bit integer, double-precision floating point, text string, or null values
- able to get last insert row ID and total number of changes which are needed to help match some of the capabilities of the _draft_ Web SQL spec
- extremely simple, rudimentary error handling

## Some known limitations

- only tested with in-memory databases (<https://www.sqlite.org/inmemorydb.html>)
- not able to close database connection and release internal resources
- hard limit of 5000 open SQLite database connections, due to this initial implementation of the design
- The API was not designed to support parallel database access through the same database connection. The workaround is to open multiple SQLite connections to the same database file name.
- Background threading would need to be done in a higher-level component.
- The required `scc_init()` initialization function should be called from the main thread upon startup, is __NOT__ thread-safe.
- Some build and run-time options used by the cordova-sqlite-storage plugin that were needed for extra safety against possible database corruption are missing in this preview.
- The `sqlite-connection-core.h` API header file and Java interface class do not have documentation comments.
- Formal documentation of the API is missing here.
- Some of the Cordova demo code needs better variable names and likely some other forms of code cleanup.

## Samples

### C API sample

```c
#include "sqlite-connection-core.h"

#include <stdio.h>

#include <stdlib.h>

#include <string.h>

static void demo() {
  const int connection_id = scc_open_connection(":memory:", 2);

  int result_check;

  if (connection_id < 0) {
    fprintf(stderr, "could not open connection");
    exit(1);
  }

  result_check = scc_begin_statement(connection_id,
    "SELECT UPPER(?) AS result1, -? as result2");
  if (result_check != 0) {
    fprintf(stderr, "could not prepare statement");
    exit(1);
  }

  result_check = scc_bind_text(connection_id, 1, "Test");
  if (result_check != 0) {
    fprintf(stderr, "could not bind text");
    exit(1);
  }

  result_check = scc_bind_double(connection_id, 2, 123.456789);
  if (result_check != 0) {
    fprintf(stderr, "could not bind double");
    exit(1);
  }

  // should get rows:
  while (scc_step(connection_id) == 100) {
    int column_index;
    const int column_count = scc_get_column_count(connection_id);

    printf("column count: %d\n", column_count);

    for (column_index = 0; column_index < column_count; ++column_index) {
      int column_type;

      printf("column index: %d\n", column_index);

      column_type = scc_get_column_type(connection_id, column_index);

      printf("  column type: %d\n", column_index);

      if (column_type == SCC_COLUMN_TYPE_FLOAT ||
          column_type == SCC_COLUMN_TYPE_INTEGER) {
        double doubleValue = scc_get_column_double(connection_id, column_index);
        printf("  double column value: %lf\n", doubleValue);
      } else {
        const char * textValue =
          scc_get_column_text(connection_id, column_index);
        printf("  text value: %s\n", textValue);
      }
    }
  }

  scc_end_statement(connection_id);
}

int main(int argc, char ** argv) {
  scc_init();
  demo();
}
```

### Java API sample

```java
import io.sqlc.SCCoreGlue;

class SQLiteDemo {
  public static void main(String [] args) {
    final int connection_id = SCCoreGlue.scc_open_connection(":memory:", 2);

    if (connection_id < 0) {
      throw new RuntimeException("could not open connection");
    }

    int resultCheck;

    resultCheck = SCCoreGlue.scc_begin_statement(connection_id,
      "SELECT UPPER(?) AS result1, -? as result2");
    if (resultCheck != 0) {
      throw new RuntimeException("could not prepare statement");
    }

    resultCheck = SCCoreGlue.scc_bind_text(connection_id, 1, "Test");
    if (resultCheck != 0) {
      throw new RuntimeException("could not bind text");
    }

    resultCheck = SCCoreGlue.scc_bind_double(connection_id, 2, 123.456789);
    if (resultCheck != 0) {
      throw new RuntimeException("could not bind double");
    }

    // should get rows:
    while (SCCoreGlue.scc_step(connection_id) == 100) {
      final int column_count = SCCoreGlue.scc_get_column_count(connection_id);

      System.out.println("column count: " + column_count);

      for (int column_index = 0; column_index < column_count; ++column_index) {
        System.out.println("column index: " + column_index);

        int column_type =
          SCCoreGlue.scc_get_column_type(connection_id, column_index);

        System.out.println("  column type: " + column_index);

        if (column_type == SCCoreGlue.SCC_COLUMN_TYPE_FLOAT ||
            column_type == SCCoreGlue.SCC_COLUMN_TYPE_INTEGER) {
          double doubleValue =
            SCCoreGlue.scc_get_column_double(connection_id, column_index);
          System.out.println("  double column value: " + doubleValue);
        } else {
          String textValue =
            SCCoreGlue.scc_get_column_text(connection_id, column_index);
          System.out.println("  text value: " + textValue);
        }
      }
    }

    SCCoreGlue.scc_end_statement(connection_id);
  }

  static {
    System.loadLibrary("sqlite-connection-core-glue");
    SCCoreGlue.scc_init();
  }
}
```

### API sample output

The C and Java samples above would both show the following output:

```
column count: 2
column index: 0
  column type: 0
  text value: TEST
column index: 1
  column type: 1
  double column value: -123.456789
```

### Apache Cordova demo app

```js
document.addEventListener('deviceready', onReady)

function onReady () {
  window.openDatabaseConnection(':memory:', 2, openCallback)
}

function openCallback (connectionId) {
  console.log('got connectionId: ' + connectionId)
  window.executeBatch(
    connectionId,
    [
      ['SELECT ?, -?, LOWER(?), UPPER(?)', [null, 123.456789, 'ABC', 'Text']],
      ['SLCT 1', []],
      ['SELECT ?', ['OK', 'out of bounds parameter']],
      ['CREATE TABLE Testing (data NOT NULL)', []],
      ["INSERT INTO Testing VALUES ('test data')", []],
      ['INSERT INTO Testing VALUES (null)', []],
      ['DELETE FROM Testing', []],
      ["INSERT INTO Testing VALUES ('test data 2')", []],
      ["INSERT INTO Testing VALUES ('test data 3')", []],
      ['SELECT * FROM Testing', []],
      ["SELECT 'xyz'", []]
    ],
    batchCallback
  )
}

function batchCallback (batchResults) {
  // show batch results in JSON string format (on all platforms)
  console.log('received batch results')
  console.log(JSON.stringify(batchResults))
  window.alert('received batch results: ' + JSON.stringify(batchResults))
}
```

### expected Cordova batch results

expected JavaScript batch results in JSON string format - reformatted by `prettier-standard`:

```json
[
  {
    "status": 0,
    "rows": [
      { "?": null, "-?": -123.456789, "LOWER(?)": "abc", "UPPER(?)": "TEXT" }
    ]
  },
  { "status": 1, "message": "near \"SLCT\": syntax error" },
  { "status": 1, "message": "column index out of range" },
  { "status": 0, "total_changes": 0, "last_insert_rowid": 0 },
  { "status": 0, "total_changes": 1, "last_insert_rowid": 1 },
  { "status": 1, "message": "NOT NULL constraint failed: Testing.data" },
  { "status": 0, "total_changes": 2, "last_insert_rowid": 1 },
  { "status": 0, "total_changes": 3, "last_insert_rowid": 1 },
  { "status": 0, "total_changes": 4, "last_insert_rowid": 2 },
  {
    "status": 0,
    "rows": [{ "data": "test data 2" }, { "data": "test data 3" }]
  },
  { "status": 0, "rows": [{ "'xyz'": "xyz" }] }
]
```

## Testing

### C test

- `cd ctest`
- `make test`

### Java JNI test

intended for testing on macOS only:

- `cd sccglue`
- `make test`

### Running Cordova demo

prerequisites:

- intended to be built and run from macOS only
- install Apache Cordova using npm (`npm i -g cordova`)
- install Xcode
- install Android SDK

how:

- `(cd sccglue && make ndkbuild)`
- `cd cordova-demo`
- `make prepare-app`
- recommended: do `cordova plugin ls` to check that the demo plugin was added
- `(cordova platform add osx && cordova run osx)` to build and run on Cordova "osx" (macOS) platform
- `(cordova platform add android && cordova run android)`
- `(cordova platform add ios && cordova run ios)`

## build notes

- Makefiles are designed to fetch and extract recent SQLite amalgamation as needed to build test programs, NDK library, and Cordova demo.
