//
//  TestRLAppLogger.m
//  iPhoneClient
//
//  Created by Reilost on 7/25/12.
//
#import "Reachability.h"
#import "RLAppLogger.h"
#import "AFURLConnectionOperation.h"
#import "RLHttpClient.h"
@interface TestRLAppLogger : GHAsyncTestCase

@end
@implementation TestRLAppLogger

- (void) testShareLogger{
    RLAppLogger *logger= [RLAppLogger sharedLogger];
    [logger log:@"%@",@"hahah"];
//    Reachability *reach = [Reachability reachabilityForInternetConnection];
//    if (reach.isReachable) {
//        NSLog(@"reach.isReachable");
//        if (reach.isReachableViaWiFi) {
//            NSLog(@"isReachableViaWiFi");
//        }else if(reach.isReachableViaWWAN){
//            NSLog(@"isReachableViaWWAN");
//        }else{
//            NSLog(@"is2g");
//        }
//    }
    NSURL *url = [NSURL URLWithString:@"http://i.stack.imgur.com/n7DxW.png"];
//    AFURLConnectionOperation *download= [[AFURLConnectionOperation alloc] initWithRequest:];
//    download.outputStream = [NSOutputStream outputStreamToFileAtPath:@"download.jpg" append:NO];
//    [download start];
    
      AFURLConnectionOperation *requestOperation = [[AFURLConnectionOperation alloc] initWithRequest:[NSURLRequest requestWithURL:url]];//[[AFImageRequestOperation alloc] initWithRequest:] ;
       
     RLHttpClient *kit = [RLHttpClient sharedInstance];
    [[kit operationQueue] addOperation:requestOperation];
}
@end
