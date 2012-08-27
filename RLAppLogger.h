//
//  RLAppLogger.h
//  iPhoneClient
//
//  Created by Reilost on 7/25/12.
//

#import <Foundation/Foundation.h>
typedef enum {

    RLAppLoggerLevelDebug =0,
    RLAppLoggerLevelInfo =1,
    RLAppLoggerLevelWarn =2,
    RLAppLoggerLevelError =3,
    RLAppLoggerLevelOff =4,
} RLAppLoggerLevel;

@interface RLAppLogger : NSObject{
    RLAppLoggerLevel _logLevel;
    RLAppLoggerLevel _httpLogLevel;
    NSArray *_logLevelName;
    BOOL _logToOneFile;
    NSString *_logDirectoryPath;
    NSSet *_ignogreFiles;
}
+ (RLAppLogger *)sharedLogger;
- (void) debug: (NSString *) format, ... ;
- (void) info: (NSString *) format, ... ;
- (void) warn: (NSString *) format, ... ;
- (void) error: (NSString *) format, ... ;
@end
