//
//  RLAppLogger.m
//  iPhoneClient
//
//  Created by Reilost on 7/25/12.
//

#import "RLAppLogger.h"
#import "AFHTTPRequestOperation.h"
#import "NSObject+Additions.h"
#import "DataCompressorKit.h"
@implementation RLAppLogger
#pragma mark share logger and life 
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
        _logLevelName=@[ @"DEBUG",@"INFO",@"WARN",@"ERROR"];
        _logLevel = RLAppLoggerLevelOff;
        _httpLogLevel = RLAppLoggerLevelOff;
        _logToOneFile = NO;
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
            
            _logToOneFile = [[configDict objectForKey:@"LOG_TO_ONE_FILE"] boolValue];
            [self configLogFiles];
        }



        
    }
    return self;
}


#pragma mark public log method
- (void) debug: (NSString *) format, ... {
    va_list args;
    va_start(args,format);
    [self log:RLAppLoggerLevelDebug :format :args];
    va_end(args);}

- (void) warn: (NSString *) format, ... {
    va_list args;
    va_start(args,format);
    [self log:RLAppLoggerLevelWarn :format :args];
    va_end(args);
}
- (void) error: (NSString *) format, ... {
    va_list args;
    va_start(args,format);
    [self log:RLAppLoggerLevelError:format :args];
    va_end(args);}


- (void) info: (NSString *) format, ... {
    va_list args;
    va_start(args,format);
    [self log:RLAppLoggerLevelInfo :format :args];
    va_end(args);
}

#pragma mark private log method
- (void) log:(RLAppLoggerLevel ) level :(NSString *) format :(va_list )args {
    if (_logLevel ==RLAppLoggerLevelOff) {
        return;
    }
    if (_logLevel <=level) {
        [self write:level :format :args];
    }

}

- (void) write:(RLAppLoggerLevel)logLevel :(NSString *) format :(va_list )args{
    NSString *logEntry = [[NSString alloc] initWithFormat:format arguments:args];
    [self write:logLevel logInfo:logEntry];
   
}
- (void)  write:(RLAppLoggerLevel)logLevel logInfo:(NSString *) logInfo {
    dispatch_block_t block =^(){
        NSString *formattedLog =  [NSString stringWithFormat:@"%@ - [%@] - %@",
                                   [_logLevelName objectAtIndex:logLevel],[NSDate date],logInfo];
        
        if (_logLevel == RLAppLoggerLevelDebug || _httpLogLevel ==RLAppLoggerLevelDebug) {
            printf("%s\r\n", [formattedLog UTF8String]);
        }
        NSString  *fileName;
        if (_logToOneFile) {
            fileName =  @"applog.log";
        }else{
           fileName  = [NSString stringWithFormat:@"%@.log",[_logLevelName objectAtIndex:logLevel]];
        }
        NSString * filePath = [_logDirectoryPath stringByAppendingPathComponent:fileName];
        NSData *logEntry =  [[formattedLog stringByAppendingString:@"\r\n"]
                             dataUsingEncoding:NSUTF8StringEncoding];

        FILE *p = fopen([filePath fileSystemRepresentation], "a");
        fwrite((const uint8_t *)[logEntry bytes], 1, [logEntry length], p);
        fclose(p);

                
    };
    dispatch_queue_t queue =dispatch_get_current_queue();
    if (queue != dispatch_get_main_queue()) {
        dispatch_async(queue, block);
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
    }
}



#pragma mark http log
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
            log=[NSString stringWithFormat:@"HTTP-START:'%@' ,'%@' ",
                 [operation.request HTTPMethod],
                 [[operation.request URL] absoluteString]];
        }else{
            log=[NSString stringWithFormat:@"HTTP-START:'%@' ,'%@' ,'%@','%@' ",
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
        log= [NSString stringWithFormat:@"HTTP-ERROR:'%@' , '%@','%@ ms', (%ld):'%@'",
              [operation.request HTTPMethod],
              [[operation.response URL] absoluteString],
              costTime,
              (long)[operation.response statusCode],
              operation.error ];
        [self write:RLAppLoggerLevelError logInfo:log];
        return;
    }
    
    
    if (_httpLogLevel == RLAppLoggerLevelInfo) {
        log=[NSString stringWithFormat:@"HTTP-END:'%@' ,'%@' ,'%@ ms', (%ld)",
             [operation.request HTTPMethod],
             [[operation.response URL] absoluteString],
             costTime,
             (long)[operation.response statusCode]];
    }else{
        log=[NSString stringWithFormat:@"HTTP-END:'%@' ,'%@' ,'%@ ms', (%ld):'%@'",
             [operation.request HTTPMethod],
             [[operation.response URL] absoluteString],
             costTime,
             (long)[operation.response statusCode],
             responseString];
    }
    
    
    [self write:_httpLogLevel logInfo:log];
    
}
#pragma mark log pipline
- (void) configLogFiles{
    if (_logLevel == RLAppLoggerLevelOff && _httpLogLevel == RLAppLoggerLevelOff) {
        return;
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    _logDirectoryPath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Logs"] ;
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSError *error;
    if (![fm fileExistsAtPath:_logDirectoryPath]) {
        [fm createDirectoryAtPath:_logDirectoryPath
      withIntermediateDirectories:YES
                       attributes:nil
                            error:&error];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sendLogFile:)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
}

- (void) tarAndSendLog:(NSString *) logFileName{
    NSString *newFileName = [NSString stringWithFormat:@"%d_%@",
                             (int)[[NSDate date] timeIntervalSince1970],
                             logFileName];
    NSString *zipFileName = [NSString stringWithFormat:@"%@.tar",newFileName];
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString * filePath = [_logDirectoryPath stringByAppendingPathComponent:logFileName];
    NSString * newFilePath = [_logDirectoryPath stringByAppendingPathComponent:newFileName];
    NSString * zipFilePath = [_logDirectoryPath stringByAppendingPathComponent:zipFileName];
    if ([fm fileExistsAtPath:filePath]) {
        [fm moveItemAtPath:filePath toPath:newFilePath error:nil];
        [DataCompressorKit compressDataFromFile:newFilePath toFile:zipFilePath error:nil];
        [fm removeItemAtPath:newFilePath error:nil];
        [DataCompressorKit uncompressDataFromFile:zipFilePath toFile:filePath error:nil];
    }
}
- (void)sendLogFile:(NSNotification *)notification {
    dispatch_block_t block =^(){
        NSString *fileName;
        if (_logToOneFile) {
            fileName =  @"applog.log";
            [self tarAndSendLog:fileName];
        }else{
            for (int i =0; i<RLAppLoggerLevelOff; i++) {
                fileName = [NSString stringWithFormat:@"%@.log",[_logLevelName objectAtIndex:i]];
                [self tarAndSendLog:fileName];
            }
        }
    };
    dispatch_queue_t queue =dispatch_get_current_queue();
    if (queue != dispatch_get_main_queue()) {
        dispatch_async(queue, block);
    }else{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), block);
    }
}

@end
