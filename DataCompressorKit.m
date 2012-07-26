//
//  DataCompressorKit.m
//  iPhoneClient
//
//  Created by Reilost on 7/26/12.
//

#import "DataCompressorKit.h"
#define DATA_CHUNK_SIZE 262144 
#define COMPRESSION_AMOUNT Z_DEFAULT_COMPRESSION

@implementation DataCompressorKit
@synthesize streamReady;

- (void)dealloc{
    if (streamReady) {
        [self closeStream];
    }
}
- (void)setupStream
{
	if (streamReady) {
		return ;
	}
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.avail_in = 0;
	zStream.next_in = 0;
	int status = deflateInit2(&zStream, COMPRESSION_AMOUNT, Z_DEFLATED, (15+16), 8, Z_DEFAULT_STRATEGY);
	if (status != Z_OK) {
		return;
	}
	streamReady = YES;
	return ;
}
- (void) setupUnCompressStream{
    if (streamReady) {
		return ;
	}
	// Setup the inflate stream
	zStream.zalloc = Z_NULL;
	zStream.zfree = Z_NULL;
	zStream.opaque = Z_NULL;
	zStream.avail_in = 0;
	zStream.next_in = 0;
	int status = inflateInit2(&zStream, (15+32));
	if (status != Z_OK) {
		return ;
	}
	streamReady = YES;
	return ;
}
- (void)closeStream
{
	if (!streamReady) {
		return ;
	}
	streamReady = NO;
	int status = deflateEnd(&zStream);
	if (status != Z_OK) {
		return ;
	}
	return ;
}
- (void )closeUnCompressStream
{
	if (!streamReady) {
		return ;
	}
	streamReady = NO;
	int status = inflateEnd(&zStream);
	if (status != Z_OK) {
		return ;
	}
	return ;
}
- (NSData *)compressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err shouldFinish:(BOOL)shouldFinish
{
	if (length == 0) return nil;
	
	NSUInteger halfLength = length/2;

	NSMutableData *outputData = [NSMutableData dataWithLength:length/2];
	
	int status;
	
	zStream.next_in = bytes;
	zStream.avail_in = (unsigned int)length;
	zStream.avail_out = 0;
    
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_out == 0) {
		
		if (zStream.total_out-bytesProcessedAlready >= [outputData length]) {
			[outputData increaseLengthBy:halfLength];
		}
		
		zStream.next_out = (Bytef*)[outputData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([outputData length] - (zStream.total_out-bytesProcessedAlready));
		status = deflate(&zStream, shouldFinish ? Z_FINISH : Z_NO_FLUSH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
			return nil;
		}
	}
	[outputData setLength: zStream.total_out-bytesProcessedAlready];
	return outputData;
}


+ (BOOL)compressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
  
	if (![fileManager createFileAtPath:destinationPath contents:[NSData data] attributes:nil]) {
		
		return NO;
	}
	

	if (![fileManager fileExistsAtPath:sourcePath]) {
		return NO;
	}
	
	UInt8 inputData[DATA_CHUNK_SIZE];
	NSData *outputData;
	NSInteger readLength;
	NSError *theError = nil;
	
	DataCompressorKit *compressor = [[DataCompressorKit alloc ] init];
                                     
    [compressor setupStream];;
	
	NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
	[inputStream open];
	NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
	[outputStream open];
	
    while ([compressor streamReady]) {
        readLength = [inputStream read:inputData maxLength:DATA_CHUNK_SIZE];
        if ([inputStream streamStatus] == NSStreamEventErrorOccurred) {
            [compressor closeStream];
			return NO;
		}
		
		if (!readLength) {
			break;
		}
        
		outputData = [compressor compressBytes:inputData
                                        length:readLength
                                         error:&theError
                                  shouldFinish:readLength < DATA_CHUNK_SIZE ];
		if (theError) {
			if (err) {
				*err = theError;
			}
			[compressor closeStream];
			return NO;
		}
		[outputStream write:(const uint8_t *)[outputData bytes] maxLength:[outputData length]];

		if ([inputStream streamStatus] == NSStreamEventErrorOccurred) {
			
			[compressor closeStream];
			return NO;
		}
		
    }
	[inputStream close];
	[outputStream close];    
	[compressor closeStream];

	return YES;
}

- (NSData *)uncompressBytes:(Bytef *)bytes length:(NSUInteger)length error:(NSError **)err
{
	if (length == 0) return nil;
	
	NSUInteger halfLength = length/2;
	NSMutableData *outputData = [NSMutableData dataWithLength:length+halfLength];
    
	int status;
	
	zStream.next_in = bytes;
	zStream.avail_in = (unsigned int)length;
	zStream.avail_out = 0;
	
	NSInteger bytesProcessedAlready = zStream.total_out;
	while (zStream.avail_in != 0) {
		
		if (zStream.total_out-bytesProcessedAlready >= [outputData length]) {
			[outputData increaseLengthBy:halfLength];
		}
		
		zStream.next_out = (Bytef*)[outputData mutableBytes] + zStream.total_out-bytesProcessedAlready;
		zStream.avail_out = (unsigned int)([outputData length] - (zStream.total_out-bytesProcessedAlready));
		
		status = inflate(&zStream, Z_NO_FLUSH);
		
		if (status == Z_STREAM_END) {
			break;
		} else if (status != Z_OK) {
			return nil;
		}
	}
	[outputData setLength: zStream.total_out-bytesProcessedAlready];
	return outputData;
}

+ (BOOL)uncompressDataFromFile:(NSString *)sourcePath toFile:(NSString *)destinationPath error:(NSError **)err
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
   
	if (![fileManager createFileAtPath:destinationPath contents:[NSData data] attributes:nil]) {
		return NO;
	}
	if (![fileManager fileExistsAtPath:sourcePath]) {
		return NO;
	}
	
	UInt8 inputData[DATA_CHUNK_SIZE];
	NSData *outputData;
	NSInteger readLength;
	NSError *theError = nil;
	
    DataCompressorKit *decompressor = [[DataCompressorKit alloc ] init];
    
    [decompressor setupUnCompressStream];;

    
	NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
	[inputStream open];
	NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:destinationPath append:NO];
	[outputStream open];
	
    while ([decompressor streamReady]) {
		
		readLength = [inputStream read:inputData maxLength:DATA_CHUNK_SIZE];
		

		if ([inputStream streamStatus] == NSStreamEventErrorOccurred) {
            [decompressor closeUnCompressStream];
			return NO;
		}

		if (!readLength) {
			break;
		}
  
        outputData = [decompressor uncompressBytes:inputData length:readLength error:&theError];
		if (theError) {
            [decompressor closeUnCompressStream];
			return NO;
		}
		
		[outputStream write:(Bytef*)[outputData bytes] maxLength:[outputData length]];
		

		if ([inputStream streamStatus] == NSStreamEventErrorOccurred) {
            [decompressor closeUnCompressStream];
			return NO;
		}
		
    }
	
	[inputStream close];
	[outputStream close];
    
    [decompressor closeUnCompressStream];
		
    return YES;
}
@end
