
#include "test.c"

#include "sqlite3.c"

// XXX BOGUS:
int sqlite3_key(void *, const char *, int);

#include "sqlite-connection-core.c"

// XXX TODO TEST proper usage of the (BOGUS) sqlite3_key()

// XXX BOGUS:
int sqlite3_key(void * db, const char * key, int len)
{
  return 1; // ERROR
}
