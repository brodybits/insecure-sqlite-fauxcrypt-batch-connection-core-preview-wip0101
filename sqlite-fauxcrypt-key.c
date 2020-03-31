#ifdef SQLITE_FAUXCRYPT_KEY_ENABLED

#include "sqlite-fauxcrypt-key.h"

#include <string.h>

#define FAUXCRYPT_CORRECT_KEY "correct"

int sqlite3_key(void * db, const char * key, int length)
{
  if (strcmp(key, FAUXCRYPT_CORRECT_KEY) == 0 &&
      length == strlen(FAUXCRYPT_CORRECT_KEY)) {
    // OK
    return 0;
  } else {
    // ERROR
    return 1;
  }
}

#endif
