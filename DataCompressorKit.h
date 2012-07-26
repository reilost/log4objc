//
//  DataCompressorKit.h
//  iPhoneClient
//
//  Created by Reilost on 7/26/12.
//  edit from ASIDataDecompressor & ASIDataCompressor
//
//  ASIDataDecompressor.m
//  Part of ASIHTTPRequest -> http://allseeing-i.com/ASIHTTPRequest
//
//  Created by Ben Copsey on 17/08/2010.
//  Copyright 2010 All-Seeing Interactive. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <zlib.h>
@interface DataCompressorKit :NSObject {
	BOOL streamReady;
	z_stream zStream;
}
@property  BOOL streamReady;

+ (BOOL)compressDataFromFile:(NSString *)sourcePath
                      toFile:(NSString *)destinationPath
                       error:(NSError **)err;

+ (BOOL)uncompressDataFromFile:(NSString *)sourcePath
                        toFile:(NSString *)destinationPath
                         error:(NSError **)err;



@end



