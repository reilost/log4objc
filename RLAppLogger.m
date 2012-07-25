//
//  RLAppLogger.m
//  iPhoneClient
//
//  Created by Reilost on 7/25/12.
//

#import "RLAppLogger.h"
#import "AFHTTPRequestOperation.h"
#import "NSObject+Additions.h"

@implementation RLAppLogger{
    RLAppLoggerLevel _logLevel;
    RLAppLoggerLevel _httpLogLevel;
    NSArray *_logLevelName;
}

+ (RLAppLogger *)sharedLogger{
    static RLAppLogger *_sharedLogger = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedLogger = [[RLAppLogger alloc] init];
    });
     
    return _sharedLogger;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (id) init{
    self = [super init];
    if (self) {
        _logLevel = RLAppLoggerLevelOff;
        _httpLogLevel =RLAppLoggerLevelOff;
        NSString *configFilePath = [[NSBundle mainBundle] pathForResource:@"LogConfig"
                                                                   ofType:@"plist"];
        NSDictionary *configDict = [NSDictionary dictionaryWithContentsOfFile:configFilePath];
        if ([configDict count] > 0) {
            int logLevel = [[configDict objectForKey:@"LOG_LEVEL"] intValue];
            if (logLevel >= RLAppLoggerLevelDebug && logLevel <RLAppLoggerLevelOff) {
                _logLevel = logLevel;
 
            }
            int httpLogLevel = [[configDict objectForKey:@"LOG_AFNETWORKING_LEVEL"] intValue];
            if (httpLogLevel >= RLAppLoggerLevelDebug && httpLogLevel <RLAppLoggerLevelOff) {
                _httpLogLevel =httpLogLevel;
                [self startLogHttpInfo];
            }
        }
//#if __has_feature(objc_array_literals)
        _logLevelName=@[ @"DEBUG",@"INFO",@"WARN",@"ERROR"];
//#else
//        id objects[] = { @"DEBUG",@"INFO",@"WARN",@"ERROR"};
//        _logLevelName= [NSArray arrayWithObjects:objects count:4];
//#endif
        
    }
    return self;
}

- (void) startLogHttpInfo{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(HTTPOperationDidStart:)
                                                 name:AFNetworkingOperationDidStartNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(HTTPOperationDidFinish:)
                                                 name:AFNetworkingOperationDidFinishNotification
                                               object:nil];
}
- (void) log: (NSString *) format, ... {
    if (_logLevel ==RLAppLoggerLevelOff) {
        return;
    }
    va_list args;
    va_start(args,format);
    if (_logLevel <=RLAppLoggerLevelInfo ) {
        [self write:RLAppLoggerLevelInfo :format :args];
    }
    va_end(args);
    
}

- (void) error: (NSString *) format, ... {
    if (_logLevel ==RLAppLoggerLevelOff) {
        return;
    }
    va_list args;
    va_start(args,format);
//    [[LogUtil shareUtil] write:2 :format :args];
    va_end(args);
}

- (void) write:(RLAppLoggerLevel)logLevel :(NSString *) format :(va_list )args{
    NSString *logEntry = [[NSString alloc] initWithFormat:format arguments:args];
    [self write:logLevel logInfo:logEntry];
   
}
- (void)  write:(RLAppLoggerLevel)logLevel logInfo:(NSString *) logInfo {
    dispatch_block_t block =^(){
        NSString *formattedLog =  [NSString stringWithFormat:@"%@ - [%@] - %@",
                                   _logLevelName[logLevel],[NSDate date],logInfo];
        
        if (_logLevel == RLAppLoggerLevelDebug) {
            printf("%s\r\n", [formattedLog UTF8String]);
        }
    };
    dispatch_queue_t queue =dispatch_get_current_queue();
    if (queue != dispatch_get_main_queue()) {
        dispatch_async(queue, block);
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
    }
}


- (void)HTTPOperationDidStart:(NSNotification *)notification {
    AFHTTPRequestOperation *operation = (AFHTTPRequestOperation *)[notification object];


    NSNumber *startTime =@(CFAbsoluteTimeGetCurrent());
    [operation associateValue:startTime withKey:@"start_time"];
    NSString *body = nil;
    if ([operation.request HTTPBody]) {
        body = [NSString stringWithUTF8String:[[operation.request HTTPBody] bytes]];
    }
    
    if (_httpLogLevel<=RLAppLoggerLevelInfo) {
        NSString *log;
        if (_httpLogLevel == RLAppLoggerLevelInfo) {
            log=[NSString stringWithFormat:@"HTTP:'%@' ,'%@' ",
                 [operation.request HTTPMethod],
                 [[operation.request URL] absoluteString]];
        }else{
            log=[NSString stringWithFormat:@"HTTP:'%@' ,'%@' ,'%@','%@' ",
                 [operation.request HTTPMethod],
                 [[operation.request URL] absoluteString],
                 [operation.request allHTTPHeaderFields],
                 body ];
        }
        [self write:_httpLogLevel logInfo:log];
    }
}

- (void)HTTPOperationDidFinish:(NSNotification *)notification {
    AFHTTPRequestOperation *operation = (AFHTTPRequestOperation *)[notification object];
    
    NSString *responseString;
    if ([operation isKindOfClass:[AFHTTPRequestOperation class]]) {
        responseString =operation.responseString;
    }

    NSNumber *endTime = @(CFAbsoluteTimeGetCurrent()); 
    NSNumber *startTime = [operation associatedValueForKey:@"start_time"];
    NSNumber *costTime = @( ([endTime doubleValue]-[startTime doubleValue]) *1000 );
    NSString *log;
    if (operation.error) {
        log= [NSString stringWithFormat:@"HTTP:'%@' , '%@','%@ ms', (%ld):'%@'",
              [operation.request HTTPMethod],
              [[operation.response URL] absoluteString],
              costTime,
              (long)[operation.response statusCode],
              operation.error ];
        [self write:RLAppLoggerLevelError logInfo:log];
        return;
    }
    
    
    if (_httpLogLevel == RLAppLoggerLevelInfo) {
        log=[NSString stringWithFormat:@"HTTP:'%@' ,'%@' ,'%@ ms', (%ld)",
             [operation.request HTTPMethod],
             [[operation.response URL] absoluteString],
             costTime,
             (long)[operation.response statusCode]];
    }else{
        log=[NSString stringWithFormat:@"HTTP:'%@' ,'%@' ,'%@ ms', (%ld):'%@'",
             [operation.request HTTPMethod],
             [[operation.response URL] absoluteString],
             costTime,
             (long)[operation.response statusCode],
             responseString];
    }
    
    
    [self write:_httpLogLevel logInfo:log];

}

@end
