/*
** 2013-05-15
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
******************************************************************************
**
** This SQLite extension implements a rot13() function and a rot13
** collating sequence.
*/
#include "rot13.h"
#include "sqlite3ext.h"
SQLITE_EXTENSION_INIT1
#include <assert.h>
#include <string.h>

/*
** Perform rot13 encoding on a single ASCII character.
*/
static unsigned char rot13(unsigned char c)
{
  if (c >= 'a' && c <= 'z')
  {
    c += 13;
    if (c > 'z')
      c -= 26;
  }
  else if (c >= 'A' && c <= 'Z')
  {
    c += 13;
    if (c > 'Z')
      c -= 26;
  }
  return c;
}

static void rot13Version(
    sqlite3_context *context,
    int argc,
    sqlite3_value **argv)
{

  sqlite3_result_text(context, SQLITE_ROT13_VERSION, -1, SQLITE_STATIC);
}

/*
** Implementation of the rot13() function.
**
** Rotate ASCII alphabetic characters by 13 character positions.
** Non-ASCII characters are unchanged.  rot13(rot13(X)) should always
** equal X.
*/
static void rot13func(
    sqlite3_context *context,
    int argc,
    sqlite3_value **argv)
{
  const unsigned char *zIn;
  int nIn;
  unsigned char *zOut;
  unsigned char *zToFree = 0;
  int i;
  unsigned char zTemp[100];
  assert(argc == 1);
  if (sqlite3_value_type(argv[0]) == SQLITE_NULL)
    return;
  zIn = (const unsigned char *)sqlite3_value_text(argv[0]);
  nIn = sqlite3_value_bytes(argv[0]);
  if (nIn < sizeof(zTemp) - 1)
  {
    zOut = zTemp;
  }
  else
  {
    zOut = zToFree = (unsigned char *)sqlite3_malloc64(nIn + 1);
    if (zOut == 0)
    {
      sqlite3_result_error_nomem(context);
      return;
    }
  }
  for (i = 0; i < nIn; i++)
    zOut[i] = rot13(zIn[i]);
  zOut[i] = 0;
  sqlite3_result_text(context, (char *)zOut, i, SQLITE_TRANSIENT);
  sqlite3_free(zToFree);
}

/*
** Implement the rot13 collating sequence so that if
**
**      x=y COLLATE rot13
**
** Then
**
**      rot13(x)=rot13(y) COLLATE binary
*/
static int rot13CollFunc(
    void *notUsed,
    int nKey1, const void *pKey1,
    int nKey2, const void *pKey2)
{
  const char *zA = (const char *)pKey1;
  const char *zB = (const char *)pKey2;
  int i, x;
  for (i = 0; i < nKey1 && i < nKey2; i++)
  {
    x = (int)rot13(zA[i]) - (int)rot13(zB[i]);
    if (x != 0)
      return x;
  }
  return nKey1 - nKey2;
}

static sqlite3_module rot13Module = {
    0, /* iVersion */
    0, /* xCreate */
    0, /* xConnect */
    0, /* xBestIndex */
    0, /* xDisconnect */
    0, /* xDestroy */
    0, /* xOpen - open a cursor */
    0, /* xClose - close a cursor */
    0, /* xFilter - configure scan constraints */
    0, /* xNext - advance a cursor */
    0, /* xEof - check for end of scan */
    0, /* xColumn - read data */
    0, /* xRowid - read data */
    0, /* xUpdate */
    0, /* xBegin */
    0, /* xSync */
    0, /* xCommit */
    0, /* xRollback */
    0, /* xFindMethod */
    0, /* xRename */
    0, /* xSavepoint */
    0, /* xRelease */
    0, /* xRollbackTo */
    0  /* xShadowName */
};

#ifdef _WIN32
__declspec(dllexport)
#endif
    int sqlite3_rot_init(
        sqlite3 *db,
        char **pzErrMsg,
        const sqlite3_api_routines *pApi)
{
  int rc = SQLITE_OK;
  SQLITE_EXTENSION_INIT2(pApi);
  (void)pzErrMsg; /* Unused parameter */
  int flags = SQLITE_UTF8 | SQLITE_INNOCUOUS | SQLITE_DETERMINISTIC;
  rc = sqlite3_create_function(db, "rot13", 1, flags, 0, rot13func, 0, 0);
  if (rc == SQLITE_OK)
  {
    rc = sqlite3_create_collation(db, "rot13", SQLITE_UTF8, 0, rot13CollFunc);
  }
  if (rc == SQLITE_OK)
  {
    rc = sqlite3_create_function_v2(db, "rot13_version", 0, flags, 0, rot13Version, 0, 0, 0);
  }
  if (rc == SQLITE_OK)
  {
    rc = sqlite3_create_module(db, "rot13", &rot13Module, 0);
  }
  return rc;
}
