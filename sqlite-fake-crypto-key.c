#ifdef SQLITE_FAKE_CRYPTO_KEY_ENABLED

#include "sqlite-fake-crypto-key.h"

#include <string.h>

#define FAKE_CRYPTO_CORRECT_KEY "correct"

int sqlite3_key(void * db, const char * key, int length)
{
  if (strcmp(key, FAKE_CRYPTO_CORRECT_KEY) == 0 &&
      length == strlen(FAKE_CRYPTO_CORRECT_KEY)) {
    // OK
    return 0;
  } else {
    // ERROR
    return 1;
  }
}

#endif
