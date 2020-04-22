#import <Cordova/CDVPlugin.h>

#include "sqlite-connection-core.h"

@interface SQLiteDemo : CDVPlugin

- (void) openDatabaseConnection: (CDVInvokedUrlCommand *) commandInfo;

- (void) executeBatch: (CDVInvokedUrlCommand *) commandInfo;

@end

@implementation SQLiteDemo

- (void) pluginInitialize
{
  scc_init();
}

- (void) openDatabaseConnection: (CDVInvokedUrlCommand *) commandInfo
{
  NSArray * _args = commandInfo.arguments;

  NSDictionary * options = (NSDictionary *)[_args objectAtIndex: 0];

  const char * filename = [(NSString *)[options valueForKey: @"path"] cString];

  const int flags = [(NSNumber *)[options valueForKey: @"flags"] intValue];

  const char * key = [(NSString *)[options valueForKey: @"key"] cString];

  const int connection_id = scc_open_connection(filename, flags);

  if (connection_id < 0) {
    CDVPluginResult * openErrorResult =
      [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                        messageAsString: @"open error"];
    [self.commandDelegate sendPluginResult: openErrorResult
                                callbackId: commandInfo.callbackId];
    return;
  }

  if (scc_key(connection_id, key) != 0) {
    CDVPluginResult * testResult =
      [CDVPluginResult resultWithStatus: CDVCommandStatus_ERROR
                        messageAsString: @"key error"];
    [self.commandDelegate sendPluginResult: testResult
                                callbackId: commandInfo.callbackId];
    return;
  }

  CDVPluginResult * openResult =
    [CDVPluginResult resultWithStatus: CDVCommandStatus_OK
                         messageAsInt: connection_id];

  [self.commandDelegate sendPluginResult: openResult
                              callbackId: commandInfo.callbackId];
}

- (void) executeBatch: (CDVInvokedUrlCommand *) commandInfo
{
  NSArray * _args = commandInfo.arguments;

  const int connection_id = [(NSNumber *)[_args objectAtIndex: 0] intValue];

  NSArray * data = [_args objectAtIndex: 1];

  NSMutableArray * results = [NSMutableArray arrayWithCapacity: 0];

  for (int i=0; i < [data count]; ++i) {
    int previousTotalChanges = scc_get_total_changes(connection_id);

    NSArray * entry = [data objectAtIndex:i];

    NSString * statement = [entry objectAtIndex: 0];

    NSArray * bind = [entry objectAtIndex: 1];

    int prepareResult =
      scc_begin_statement(connection_id, [statement cString]);

    if (prepareResult == 0) {
      for (int j=0; j < [bind count]; ++j) {
        NSObject * bindValue = [bind objectAtIndex: j];

        if (bindValue == nil) {
          prepareResult = scc_bind_null(connection_id, 1 + j);
        } else if ([bindValue isKindOfClass: [NSNumber class]]) {
          // TBD UIWebView vs WKWebView
          if ([(NSNumber *)bindValue objCType][0] == 'q') {
            prepareResult = scc_bind_long(connection_id, 1 + j,
              [(NSNumber *)bindValue longValue]);
          } else {
            prepareResult = scc_bind_double(connection_id, 1 + j,
              [(NSNumber *)bindValue doubleValue]);
          }
        } else if ([bindValue isKindOfClass: [NSString class]]) {
          prepareResult = scc_bind_text(connection_id, 1 + j,
              [(NSString *)bindValue cString]);
        } else {
          prepareResult = scc_bind_null(connection_id, 1 + j);
        }
      }
    }

    if (prepareResult != 0) {
      [results addObject: @{
        @"status": @1,
        @"message": [NSString stringWithUTF8String:
          scc_get_last_error_message(connection_id)]
      }];

      scc_end_statement(connection_id);

      continue;
    }

    int stepResult = scc_step(connection_id);

    if (stepResult == 100) {
      const int columnCount = scc_get_column_count(connection_id);

      NSMutableArray * columns = [NSMutableArray arrayWithCapacity: 0];

      for (int j = 0; j < columnCount; ++j) {
        NSString * columnNameAsString =
          [NSString stringWithUTF8String: scc_get_column_name(connection_id, j)];
        [columns addObject: columnNameAsString];
      }

      NSMutableArray * rows = [NSMutableArray arrayWithCapacity: 0];

      do {
        NSMutableArray * row = [NSMutableArray arrayWithCapacity: 0];

        for (int j = 0; j < columnCount; ++j) {
          const int columnType = scc_get_column_type(connection_id, j);

          if (columnType == SCC_COLUMN_TYPE_NULL) {
            [row addObject: [NSNull null]];
          } else if (columnType == SCC_COLUMN_TYPE_INTEGER) {
            NSNumber * columnNumberValue =
              [NSNumber numberWithLongLong: scc_get_column_long(connection_id, j)];
            [row addObject: columnNumberValue];
          } else if (columnType == SCC_COLUMN_TYPE_FLOAT) {
            NSNumber * columnNumberValue =
              [NSNumber numberWithDouble: scc_get_column_double(connection_id, j)];
            [row addObject: columnNumberValue];
          } else {
            NSString * columnStringValue =
              [NSString stringWithUTF8String: scc_get_column_text(connection_id, j)];
            [row addObject: columnStringValue];
          }
        }

        [rows addObject: row];

        stepResult = scc_step(connection_id);
      } while(stepResult == 100);

      [results addObject: @{@"status":@0, @"columns": columns, @"rows": rows}];
    } else if (stepResult == 101) {
      int totalChanges = scc_get_total_changes(connection_id);
      int rowsAffected = totalChanges - previousTotalChanges;

      [results addObject: @{
        @"status": @0,
        @"rowsAffected": [NSNumber numberWithInteger: rowsAffected],
        @"totalChanges": [NSNumber numberWithInteger: totalChanges],
        @"lastInsertRowId": [NSNumber numberWithInteger:
          scc_get_last_insert_rowid(connection_id)]
      }];
    } else {
      [results addObject: @{
        @"status": @1,
        @"message": [NSString stringWithUTF8String:
          scc_get_last_error_message(connection_id)]
      }];
    }

    scc_end_statement(connection_id);
  }

  CDVPluginResult * batchResult =
    [CDVPluginResult resultWithStatus: CDVCommandStatus_OK
                       messageAsArray: results];

  [self.commandDelegate sendPluginResult: batchResult
                              callbackId: commandInfo.callbackId];
}

@end
