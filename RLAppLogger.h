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

@interface RLAppLogger : NSObject

+ (RLAppLogger *)sharedLogger;
- (void) log: (NSString *) format, ... ;
@end
