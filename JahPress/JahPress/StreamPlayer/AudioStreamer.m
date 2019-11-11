//
//  AudioStreamer.m
//  StreamingAudioPlayer
//
//  Created by Matt Gallagher on 27/09/08.
//  Copyright 2008 Matt Gallagher. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty. In no event will the authors be held liable for any damages
//  arising from the use of this software. Permission is granted to anyone to
//  use this software for any purpose, including commercial applications, and to
//  alter it and redistribute it freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source
//     distribution.
//


#import "AudioStreamer.h"
#if TARGET_OS_IPHONE			
#import <CFNetwork/CFNetwork.h>
#endif

//#import "FDIAmplifyDefinitions.h"
//
//#import "FDIVisualizerContainerViewController.h"

#define BitRateEstimationMaxPackets 5000
#define BitRateEstimationMinPackets 50

NSString * const ASStatusChangedNotification = @"ASStatusChangedNotification";

NSString * const AS_NO_ERROR_STRING = @"No error.";
NSString * const AS_FILE_STREAM_GET_PROPERTY_FAILED_STRING = @"File stream get property failed.";
NSString * const AS_FILE_STREAM_SEEK_FAILED_STRING = @"File stream seek failed.";
NSString * const AS_FILE_STREAM_PARSE_BYTES_FAILED_STRING = @"Parse bytes failed.";
NSString * const AS_FILE_STREAM_OPEN_FAILED_STRING = @"Open audio file stream failed.";
NSString * const AS_FILE_STREAM_CLOSE_FAILED_STRING = @"Close audio file stream failed.";
NSString * const AS_AUDIO_QUEUE_CREATION_FAILED_STRING = @"Audio queue creation failed.";
NSString * const AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED_STRING = @"Audio buffer allocation failed.";
NSString * const AS_AUDIO_QUEUE_ENQUEUE_FAILED_STRING = @"Queueing of audio buffer failed.";
NSString * const AS_AUDIO_QUEUE_ADD_LISTENER_FAILED_STRING = @"Audio queue add listener failed.";
NSString * const AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED_STRING = @"Audio queue remove listener failed.";
NSString * const AS_AUDIO_QUEUE_START_FAILED_STRING = @"Audio queue start failed.";
NSString * const AS_AUDIO_QUEUE_BUFFER_MISMATCH_STRING = @"Audio queue buffers don't match.";
NSString * const AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING = @"Audio queue dispose failed.";
NSString * const AS_AUDIO_QUEUE_PAUSE_FAILED_STRING = @"Audio queue pause failed.";
NSString * const AS_AUDIO_QUEUE_STOP_FAILED_STRING = @"Audio queue stop failed.";
NSString * const AS_AUDIO_DATA_NOT_FOUND_STRING = @"No audio data found.";
NSString * const AS_AUDIO_QUEUE_FLUSH_FAILED_STRING = @"Audio queue flush failed.";
NSString * const AS_GET_AUDIO_TIME_FAILED_STRING = @"Audio queue get current time failed.";
NSString * const AS_AUDIO_STREAMER_FAILED_STRING = @"Audio playback failed";
NSString * const AS_NETWORK_CONNECTION_FAILED_STRING = @"Network connection failed";
NSString * const AS_AUDIO_BUFFER_TOO_SMALL_STRING = @"Audio packets are larger than kAQDefaultBufSize.";

@interface AudioStreamer ()
@property (readwrite) AudioStreamerState state;

- (void)handleAudioQueueProcessingData:(UInt32)inNumberFrames outNumberOfFrames:(UInt32*)outNumberFrames audioBufferList:(AudioBufferList*)ioData;

- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
	fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
	ioFlags:(UInt32 *)ioFlags;
- (void)handleAudioPackets:(const void *)inInputData
	numberBytes:(UInt32)inNumberBytes
	numberPackets:(UInt32)inNumberPackets
	packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
	buffer:(AudioQueueBufferRef)inBuffer;
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
	propertyID:(AudioQueuePropertyID)inID;

#if TARGET_OS_IPHONE
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState;
#endif

- (void)internalSeekToTime:(double)newSeekTime;
- (void)enqueueBuffer;
- (void)handleReadFromStream:(CFReadStreamRef)aStream
	eventType:(CFStreamEventType)eventType;

@end

#pragma mark Audio Callback Function Implementations


static void ASAudioQueueProcessingTapCallback(
                                   void *                          inClientData,
                                   AudioQueueProcessingTapRef      inAQTap,
                                   UInt32                          inNumberFrames,
                                   AudioTimeStamp *                ioTimeStamp,
                                   UInt32 *                        ioFlags,
                                   UInt32 *                        outNumberFrames,
                                AudioBufferList *               ioData) {
    
    AudioStreamer* streamer = (__bridge AudioStreamer *)inClientData;
    [streamer handleAudioQueueProcessingData:inNumberFrames outNumberOfFrames:outNumberFrames audioBufferList:ioData];
    
}
//
// ASPropertyListenerProc
//
// Receives notification when the AudioFileStream has audio packets to be
// played. In response, this function creates the AudioQueue, getting it
// ready to begin playback (playback won't begin until audio packets are
// sent to the queue in ASEnqueueBuffer).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// kAudioQueueProperty_IsRunning listening added.
//
static void ASPropertyListenerProc(void *						inClientData,
								AudioFileStreamID				inAudioFileStream,
								AudioFileStreamPropertyID		inPropertyID,
								UInt32 *						ioFlags)
{	
	// this is called by audio file stream when it finds property values
	AudioStreamer* streamer = (__bridge AudioStreamer *)inClientData;
	[streamer
		handlePropertyChangeForFileStream:inAudioFileStream
		fileStreamPropertyID:inPropertyID
		ioFlags:ioFlags];
}

//
// ASPacketsProc
//
// When the AudioStream has packets to be played, this function gets an
// idle audio buffer and copies the audio packets into it. The calls to
// ASEnqueueBuffer won't return until there are buffers available (or the
// playback has been stopped).
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
static void ASPacketsProc(		void *							inClientData,
								UInt32							inNumberBytes,
								UInt32							inNumberPackets,
								const void *					inInputData,
								AudioStreamPacketDescription	*inPacketDescriptions)
{
	// this is called by audio file stream when it finds packets of audio
	AudioStreamer* streamer = (__bridge AudioStreamer *)inClientData;
	[streamer
		handleAudioPackets:inInputData
		numberBytes:inNumberBytes
		numberPackets:inNumberPackets
		packetDescriptions:inPacketDescriptions];
}

//
// ASAudioQueueOutputCallback
//
// Called from the AudioQueue when playback of specific buffers completes. This
// function signals from the AudioQueue thread to the AudioStream thread that
// the buffer is idle and available for copying data.
//
// This function is unchanged from Apple's example in AudioFileStreamExample.
//
static void ASAudioQueueOutputCallback(void*				inClientData, 
									AudioQueueRef			inAQ, 
									AudioQueueBufferRef		inBuffer)
{
	// this is called by the audio queue when it has finished decoding our data. 
	// The buffer is now free to be reused.
	AudioStreamer* streamer = (__bridge AudioStreamer*)inClientData;
	[streamer handleBufferCompleteForQueue:inAQ buffer:inBuffer];
}

//
// ASAudioQueueIsRunningCallback
//
// Called from the AudioQueue when playback is started or stopped. This
// information is used to toggle the observable "isPlaying" property and
// set the "finished" flag.
//
static void ASAudioQueueIsRunningCallback(void *inUserData, AudioQueueRef inAQ, AudioQueuePropertyID inID)
{
	AudioStreamer* streamer = (__bridge AudioStreamer *)inUserData;
	[streamer handlePropertyChangeForQueue:inAQ propertyID:inID];
}

#if TARGET_OS_IPHONE			
//
// ASAudioSessionInterruptionListener
//
// Invoked if the audio session is interrupted (like when the phone rings)
//
static void ASAudioSessionInterruptionListener(void *inClientData, UInt32 inInterruptionState)
{
	AudioStreamer* streamer = (__bridge AudioStreamer *)inClientData;
	[streamer handleInterruptionChangeToState:inInterruptionState];
}
#endif

#pragma mark CFReadStream Callback Function Implementations

//
// ReadStreamCallBack
//
// This is the callback for the CFReadStream from the network connection. This
// is where all network data is passed to the AudioFileStream.
//
// Invoked when an error occurs, the stream ends or we have data to read.
//
static void ASReadStreamCallBack
(
   CFReadStreamRef aStream,
   CFStreamEventType eventType,
   void* inClientInfo
)
{
	AudioStreamer* streamer = (__bridge AudioStreamer *)inClientInfo;
	[streamer handleReadFromStream:aStream eventType:eventType];
}

@implementation AudioStreamer {
    
    AudioFileTypeID _fileTypeHint;
    
    NSString* _codec;
    
    //SInt16 visualizerBuffer[VIS_MAX_SAMPLES];
    
    int bytesFromStream;
    int bytesInPackets;
    
    int _calculatedBufferSize;
    
}

@synthesize delegate;
@synthesize errorCode;
@synthesize state;
@synthesize bitRate;
@synthesize httpHeaders;
@synthesize fileExtension;

@synthesize foundIcyStart;
@synthesize foundIcyEnd;
@synthesize parsedHeaders;
@synthesize metaDataString;
@synthesize streamContentType;

//
// initWithURL
//
// Init method for the object.
//
- (id)initWithURL:(NSURL *)aURL andCodec:(NSString*)codec andBitrate:(int)_bitRate
{
	self = [super init];
	if (self != nil)
	{
        
        _calculatedBufferSize = 16 * _bitRate;// kAQDefaultBufSize;
        
        NSLog(@"Calculated Buffer Size: %i", _calculatedBufferSize);
        
        self.metaDataString = nil;
        //_codec = codec;
        
		url = aURL;
        
        NSLog(@"URL: %@", url);
        
        bytesFromStream = 0;
        bytesInPackets = 0;
        
        //url = [[NSURL URLWithString:@"http://example.com:port"] retain];
        
	}
	return self;
}

//
// dealloc
//
// Releases instance memory.
//
- (void)dealloc
{
	[self stop];
	url = nil;
	fileExtension = nil;

}

//
// isFinishing
//
// returns YES if the audio has reached a stopping condition.
//
- (BOOL)isFinishing
{
	@synchronized (self)
	{
		if ((errorCode != AS_NO_ERROR && state != AS_INITIALIZED) ||
			((state == AS_STOPPING || state == AS_STOPPED) &&
				stopReason != AS_STOPPING_TEMPORARILY))
		{
			return YES;
		}
	}
	
	return NO;
}

//
// runLoopShouldExit
//
// returns YES if the run loop should exit.
//
- (BOOL)runLoopShouldExit
{
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR ||
			(state == AS_STOPPED &&
			stopReason != AS_STOPPING_TEMPORARILY))
		{
			return YES;
		}
	}
	
	return NO;
}

//
// stringForErrorCode:
//
// Converts an error code to a string that can be localized or presented
// to the user.
//
// Parameters:
//    anErrorCode - the error code to convert
//
// returns the string representation of the error code
//
+ (NSString *)stringForErrorCode:(AudioStreamerErrorCode)anErrorCode
{
	switch (anErrorCode)
	{
		case AS_NO_ERROR:
			return AS_NO_ERROR_STRING;
		case AS_FILE_STREAM_GET_PROPERTY_FAILED:
			return AS_FILE_STREAM_GET_PROPERTY_FAILED_STRING;
		case AS_FILE_STREAM_SEEK_FAILED:
			return AS_FILE_STREAM_SEEK_FAILED_STRING;
		case AS_FILE_STREAM_PARSE_BYTES_FAILED:
			return AS_FILE_STREAM_PARSE_BYTES_FAILED_STRING;
		case AS_AUDIO_QUEUE_CREATION_FAILED:
			return AS_AUDIO_QUEUE_CREATION_FAILED_STRING;
		case AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED:
			return AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED_STRING;
		case AS_AUDIO_QUEUE_ENQUEUE_FAILED:
			return AS_AUDIO_QUEUE_ENQUEUE_FAILED_STRING;
		case AS_AUDIO_QUEUE_ADD_LISTENER_FAILED:
			return AS_AUDIO_QUEUE_ADD_LISTENER_FAILED_STRING;
		case AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED:
			return AS_AUDIO_QUEUE_REMOVE_LISTENER_FAILED_STRING;
		case AS_AUDIO_QUEUE_START_FAILED:
			return AS_AUDIO_QUEUE_START_FAILED_STRING;
		case AS_AUDIO_QUEUE_BUFFER_MISMATCH:
			return AS_AUDIO_QUEUE_BUFFER_MISMATCH_STRING;
		case AS_FILE_STREAM_OPEN_FAILED:
			return AS_FILE_STREAM_OPEN_FAILED_STRING;
		case AS_FILE_STREAM_CLOSE_FAILED:
			return AS_FILE_STREAM_CLOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_DISPOSE_FAILED:
			return AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_PAUSE_FAILED:
			return AS_AUDIO_QUEUE_DISPOSE_FAILED_STRING;
		case AS_AUDIO_QUEUE_FLUSH_FAILED:
			return AS_AUDIO_QUEUE_FLUSH_FAILED_STRING;
		case AS_AUDIO_DATA_NOT_FOUND:
			return AS_AUDIO_DATA_NOT_FOUND_STRING;
		case AS_GET_AUDIO_TIME_FAILED:
			return AS_GET_AUDIO_TIME_FAILED_STRING;
		case AS_NETWORK_CONNECTION_FAILED:
			return AS_NETWORK_CONNECTION_FAILED_STRING;
		case AS_AUDIO_QUEUE_STOP_FAILED:
			return AS_AUDIO_QUEUE_STOP_FAILED_STRING;
		case AS_AUDIO_STREAMER_FAILED:
			return AS_AUDIO_STREAMER_FAILED_STRING;
		case AS_AUDIO_BUFFER_TOO_SMALL:
			return AS_AUDIO_BUFFER_TOO_SMALL_STRING;
		default:
			return AS_AUDIO_STREAMER_FAILED_STRING;
	}
	
	return AS_AUDIO_STREAMER_FAILED_STRING;
}

//
// presentAlertWithTitle:message:
//
// Common code for presenting error dialogs
//
// Parameters:
//    title - title for the dialog
//    message - main test for the dialog
//
- (void)presentAlertWithTitle:(NSString*)title message:(NSString*)message
{
#if TARGET_OS_IPHONE
	UIAlertView *alert = [
		[UIAlertView alloc]
			initWithTitle:title
			message:message
			delegate:self
			cancelButtonTitle:NSLocalizedString(@"OK", @"")
			otherButtonTitles: nil];
	[alert
		performSelector:@selector(show)
		onThread:[NSThread mainThread]
		withObject:nil
		waitUntilDone:NO];
#else
	NSAlert *alert =
		[NSAlert
			alertWithMessageText:title
			defaultButton:NSLocalizedString(@"OK", @"")
			alternateButton:nil
			otherButton:nil
			informativeTextWithFormat:message];
	[alert
		performSelector:@selector(runModal)
		onThread:[NSThread mainThread]
		withObject:nil
		waitUntilDone:NO];
#endif
}

//
// failWithErrorCode:
//
// Sets the playback state to failed and logs the error.
//
// Parameters:
//    anErrorCode - the error condition
//
- (void)failWithErrorCode:(AudioStreamerErrorCode)anErrorCode
{
    
	@synchronized(self)
	{
		if (errorCode != AS_NO_ERROR)
		{
			// Only set the error once.
			return;
		}
		
		errorCode = anErrorCode;
        
        int errorReason = 0;
        
        if (errorCode == AS_AUDIO_DATA_NOT_FOUND) {
            errorReason = 1;
        }
        
        NSString* message = @"";

		if (err)
		{
			char *errChars = (char *)&err;
            NSLog(@"%@ err: %c%c%c%c %d\n",
                 [AudioStreamer stringForErrorCode:anErrorCode],
                 errChars[3], errChars[2], errChars[1], errChars[0],
                 (int)err);
		}
		else
		{
            message = [AudioStreamer stringForErrorCode:anErrorCode];
			//NSLog(@"%@", [AudioStreamer stringForErrorCode:anErrorCode]);
		}

		if (state == AS_PLAYING ||
			state == AS_PAUSED ||
			state == AS_BUFFERING)
		{
			self.state = AS_STOPPING;
			stopReason = AS_STOPPING_ERROR;
			AudioQueueStop(audioQueue, true);
		}
        
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [delegate audioStreamerNetworkError:errorReason message:message];
        });

		//[self presentAlertWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
		//					message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)];
	}
}

//
// mainThreadStateNotification
//
// Method invoked on main thread to send notifications to the main thread's
// notification center.
//
- (void)mainThreadStateNotification
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotification *notification =
		[NSNotification
         notificationWithName:ASStatusChangedNotification
         object:self];
        [[NSNotificationCenter defaultCenter]
         postNotification:notification];
    });
    
	
}

//
// state
//
// returns the state value.
//
- (AudioStreamerState)state
{
    @synchronized(self)
	{
        return state;
    }
}

//
// setState:
//
// Sets the state and sends a notification that the state has changed.
//
// This method
//
// Parameters:
//    anErrorCode - the error condition
//
- (void)setState:(AudioStreamerState)aStatus
{
	@synchronized(self)
	{
		if (state != aStatus)
		{
			state = aStatus;
			
			dispatch_async(dispatch_get_main_queue(), ^{
                NSNotification *notification =
                [NSNotification
                 notificationWithName:ASStatusChangedNotification
                 object:self];
                [[NSNotificationCenter defaultCenter]
                 postNotification:notification];
            });
		}
	}
}

//
// isPlaying
//
// returns YES if the audio currently playing.
//
- (BOOL)isPlaying
{
	if (state == AS_PLAYING)
	{
		return YES;
	}
	
	return NO;
}

//
// isPaused
//
// returns YES if the audio currently playing.
//
- (BOOL)isPaused
{
	if (state == AS_PAUSED)
	{
		return YES;
	}
	
	return NO;
}

//
// isWaiting
//
// returns YES if the AudioStreamer is waiting for a state transition of some
// kind.
//
- (BOOL)isWaiting
{
	@synchronized(self)
	{
		if ([self isFinishing] ||
			state == AS_STARTING_FILE_THREAD||
			state == AS_WAITING_FOR_DATA ||
			state == AS_WAITING_FOR_QUEUE_TO_START ||
			state == AS_BUFFERING)
		{
			return YES;
		}
	}
	
	return NO;
}

//
// isIdle
//
// returns YES if the AudioStream is in the AS_INITIALIZED state (i.e.
// isn't doing anything).
//
- (BOOL)isIdle
{
	if (state == AS_INITIALIZED)
	{
		return YES;
	}
	
	return NO;
}

//
// hintForFileExtension:
//
// Generates a first guess for the file type based on the file's extension
//
// Parameters:
//    fileExtension - the file extension
//
// returns a file type hint that can be passed to the AudioFileStream
//
+ (AudioFileTypeID)hintForFileExtension:(NSString *)fileExtension
{
	AudioFileTypeID fileTypeHint = kAudioFileMP3Type; // MP3 als Standard
    
    if (fileExtension == nil) {
        return fileTypeHint;
    }
    
	if ([fileExtension isEqual:@"mp3"])
	{
		fileTypeHint = kAudioFileMP3Type;
	}
	else if ([fileExtension isEqual:@"wav"])
	{
		fileTypeHint = kAudioFileWAVEType;
	}
	else if ([fileExtension isEqual:@"aifc"])
	{
		fileTypeHint = kAudioFileAIFCType;
	}
	else if ([fileExtension isEqual:@"aiff"])
	{
		fileTypeHint = kAudioFileAIFFType;
	}
	else if ([fileExtension isEqual:@"m4a"])
	{
		fileTypeHint = kAudioFileM4AType;
	}
	else if ([fileExtension isEqual:@"mp4"])
	{
		fileTypeHint = kAudioFileMPEG4Type;
	}
	else if ([fileExtension isEqual:@"caf"])
	{
		fileTypeHint = kAudioFileCAFType;
	}
	else if ([fileExtension isEqual:@"aac"])
	{
		fileTypeHint = kAudioFileAAC_ADTSType;
	}
	return fileTypeHint;
}

+ (NSString*)codecNameFromFileTypeHint:(AudioFileTypeID)fileTypeHint
{
    
    if (fileTypeHint == kAudioFileMP3Type) {
        return @"mp3";
    }
    
    if (fileTypeHint == kAudioFileAAC_ADTSType) {
        return @"aac";
    }
    
    if (fileTypeHint == kAudioFileMP3Type) {
        return @"mp3";
    }
    
	return @"";
    
}

+ (AudioFileTypeID)hintForContentType:(NSString *)metaData
{
	AudioFileTypeID fileTypeHint = kAudioFileMP3Type; // MP3 als Standard
    
    if ([metaData caseInsensitiveCompare:@"audio/aac"] == NSOrderedSame) {
        fileTypeHint = kAudioFileAAC_ADTSType;
    }
    
    if ([metaData caseInsensitiveCompare:@"audio/mpeg"] == NSOrderedSame) {
        fileTypeHint = kAudioFileMP3Type;
    }
    
    if ([metaData caseInsensitiveCompare:@"audio/aacp"] == NSOrderedSame) {
        fileTypeHint = kAudioFileAAC_ADTSType;
    }
    
	return fileTypeHint;
}

//
// openReadStream
//
// Open the audioFileStream to parse data and the fileHandle as the data
// source.
//
- (BOOL)openReadStream
{
	@synchronized(self)
	{
		NSAssert([[NSThread currentThread] isEqual:internalThread],
			@"File stream download must be started on the internalThread");
		NSAssert(stream == nil, @"Download stream already initialized");
		
		//
		// Create the HTTP GET request
		//
        NSLog(@"Building Request with URL: %@", [url absoluteString]);
        
        // http://www.freundederinteraktion.de/useragenttest/index.php
        
		CFHTTPMessageRef message= CFHTTPMessageCreateRequest(NULL, (CFStringRef)@"GET", (__bridge CFURLRef)url, kCFHTTPVersion1_1);
		CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Icy-MetaData"), CFSTR("1"));
        //CFHTTPMessageSetHeaderFieldValue(message, CFSTR("User-Agent"), CFSTR("ARSCH"));
        
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("User-Agent"), CFSTR("iTunes/11.0.2 (Macintosh; OS X 10.7.5) AppleWebKit/534.57.7"));
        
        // HTTP_X_AUDIOCAST_UDPPORT: 60955
        //CFHTTPMessageSetHeaderFieldValue(message, CFSTR("HTTP_X_AUDIOCAST_UDPPORT"), CFSTR("60955"));
        
        CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Accept"), CFSTR("*/*"));
        // WinampMPEG/5.09
        
        // */*
        
        //CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Connection"), CFSTR("keep-alive"));
//        
        // 	keep-alive
        
        // User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_0) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/13.0.782.112 Safari/535.1
		//
		// If we are creating this request to seek to a location, set the
		// requested byte range in the headers.
		//
		if (fileLength > 0 && seekByteOffset > 0)
		{
			CFHTTPMessageSetHeaderFieldValue(message, CFSTR("Range"),
				(__bridge CFStringRef)[NSString stringWithFormat:@"bytes=%d-%d", seekByteOffset, fileLength]);
			discontinuous = YES;
		}
		
		//
		// Create the read stream that will receive data from the HTTP request
		//
		stream = CFReadStreamCreateForHTTPRequest(NULL, message);
		CFRelease(message);
		
		//
		// Enable stream redirection
		//
		if (CFReadStreamSetProperty(
			stream,
			kCFStreamPropertyHTTPShouldAutoredirect,
			kCFBooleanTrue) == false)
		{
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate audioStreamerNetworkError:0 message:@""];
            });
//			[self presentAlertWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
//								message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)];
			return NO;
		}
		
		//
		// Handle proxies
		//
		CFDictionaryRef proxySettings = CFNetworkCopySystemProxySettings();
		CFReadStreamSetProperty(stream, kCFStreamPropertyHTTPProxy, proxySettings);
		CFRelease(proxySettings);
		
		//
		// Handle SSL connections
		//
		if( [[url absoluteString] rangeOfString:@"https"].location != NSNotFound )
		{
			NSDictionary *sslSettings =
				[NSDictionary dictionaryWithObjectsAndKeys:
					(NSString *)kCFStreamSocketSecurityLevelNegotiatedSSL, kCFStreamSSLLevel,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredCertificates,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsExpiredRoots,
					[NSNumber numberWithBool:YES], kCFStreamSSLAllowsAnyRoot,
					[NSNumber numberWithBool:NO], kCFStreamSSLValidatesCertificateChain,
					[NSNull null], kCFStreamSSLPeerName,
				nil];

			CFReadStreamSetProperty(stream, kCFStreamPropertySSLSettings, (__bridge CFTypeRef)(sslSettings));
		}
		
		//
		// We're now ready to receive data
		//
		self.state = AS_WAITING_FOR_DATA;

		//
		// Open the stream
		//
		if (!CFReadStreamOpen(stream))
		{
			CFRelease(stream);
            stream = nil;
            dispatch_async(dispatch_get_main_queue(), ^{
                [delegate audioStreamerNetworkError:0 message:@""];
            });
//			[self presentAlertWithTitle:NSLocalizedStringFromTable(@"File Error", @"Errors", nil)
//								message:NSLocalizedStringFromTable(@"Unable to configure network read stream.", @"Errors", nil)];
			return NO;
		}
		
		//
		// Set our callback function to receive the data
		//
		CFStreamClientContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
		CFReadStreamSetClient(
			stream,
			kCFStreamEventHasBytesAvailable | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered,
			ASReadStreamCallBack,
			&context);
		CFReadStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
	}
	
	return YES;
}

//
// startInternal
//
// This is the start method for the AudioStream thread. This thread is created
// because it will be blocked when there are no audio buffers idle (and ready
// to receive audio data).
//
// Activity in this thread:
//	- Creation and cleanup of all AudioFileStream and AudioQueue objects
//	- Receives data from the CFReadStream
//	- AudioFileStream processing
//	- Copying of data from AudioFileStream into audio buffers
//  - Stopping of the thread because of end-of-file
//	- Stopping due to error or failure
//
// Activity *not* in this thread:
//	- AudioQueue playback and notifications (happens in AudioQueue thread)
//  - Actual download of NSURLConnection data (NSURLConnection's thread)
//	- Creation of the AudioStreamer (other, likely "main" thread)
//	- Invocation of -start method (other, likely "main" thread)
//	- User/manual invocation of -stop (other, likely "main" thread)
//
// This method contains bits of the "main" function from Apple's example in
// AudioFileStreamExample.
//
- (void)startInternal
{

	@synchronized(self)
	{
        
        dataBytesRead = 0;
        foundIcyStart = NO;
        foundIcyEnd = NO;
        parsedHeaders = NO;
        metaDataInterval = 0;
        metaDataBytesRemaining = 0;
        
		if (state != AS_STARTING_FILE_THREAD)
		{
			if (state != AS_STOPPING &&
				state != AS_STOPPED)
			{
				NSLog(@"### Not starting audio thread. State code is: %ld", (long)state);
			}
			self.state = AS_INITIALIZED;
			return;
		}
		
	#if TARGET_OS_IPHONE			
		//
		// Set the audio session category so that we continue to play if the
		// iPhone/iPod auto-locks.
		//
		AudioSessionInitialize (
			NULL,                          // 'NULL' to use the default (main) run loop
			NULL,                          // 'NULL' to use the default run loop mode
			ASAudioSessionInterruptionListener,  // a reference to your interruption callback
			(__bridge void *)(self)                       // data to pass to your interruption listener callback
		);
		UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
		AudioSessionSetProperty (
			kAudioSessionProperty_AudioCategory,
			sizeof (sessionCategory),
			&sessionCategory
		);
		AudioSessionSetActive(true);
	#endif
	
		// initialize a mutex and condition so that we can block on buffers in use.
		pthread_mutex_init(&queueBuffersMutex, NULL);
		pthread_cond_init(&queueBufferReadyCondition, NULL);
		
		if (![self openReadStream])
		{
			goto cleanup;
		}
	}
	
	//
	// Process the run loop until playback is finished or failed.
	//
	BOOL isRunning = YES;
	do
	{
		isRunning = [[NSRunLoop currentRunLoop]
			runMode:NSDefaultRunLoopMode
			beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];
		
		@synchronized(self) {
			if (seekWasRequested) {
				[self internalSeekToTime:requestedSeekTime];
				seekWasRequested = NO;
			}
		}
		
		//
		// If there are no queued buffers, we need to check here since the
		// handleBufferCompleteForQueue:buffer: should not change the state
		// (may not enter the synchronized section).
		//
		if (buffersUsed == 0 && self.state == AS_PLAYING)
		{
			err = AudioQueuePause(audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_BUFFERING;
		}
	} while (isRunning && ![self runLoopShouldExit]);
	
cleanup:
    
    NSLog(@"Cleanup");

	@synchronized(self)
	{
		//
		// Cleanup the read stream if it is still open
		//
		if (stream != nil)
		{
            CFReadStreamClose(stream);
			CFRelease(stream);
			stream = nil;
		}
		
		//
		// Close the audio file strea,
		//
		if (audioFileStream)
		{
			err = AudioFileStreamClose(audioFileStream);
			audioFileStream = nil;
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_CLOSE_FAILED];
			}
		}
		
		//
		// Dispose of the Audio Queue
		//
		if (audioQueue)
		{
			err = AudioQueueDispose(audioQueue, true);
			audioQueue = nil;
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_DISPOSE_FAILED];
			}
		}

		pthread_mutex_destroy(&queueBuffersMutex);
		pthread_cond_destroy(&queueBufferReadyCondition);

#if TARGET_OS_IPHONE			
		AudioSessionSetActive(false);
#endif

		httpHeaders = nil;

		bytesFilled = 0;
		packetsFilled = 0;
		seekByteOffset = 0;
		packetBufferSize = 0;
		self.state = AS_INITIALIZED;

		internalThread = nil;
	}

}

//
// start
//
// Calls startInternal in a new thread.
//
- (void)start
{
	@synchronized (self)
	{
		if (state == AS_PAUSED)
		{
			[self pause];
		}
		else if (state == AS_INITIALIZED)
		{
			NSAssert([[NSThread currentThread] isEqual:[NSThread mainThread]],
				@"Playback can only be started from the main thread.");
			notificationCenter =
				[NSNotificationCenter defaultCenter];
			self.state = AS_STARTING_FILE_THREAD;
			internalThread =
				[[NSThread alloc]
					initWithTarget:self
					selector:@selector(startInternal)
					object:nil];
			[internalThread start];
		}
	}
}


// internalSeekToTime:
//
// Called from our internal runloop to reopen the stream at a seeked location
//
- (void)internalSeekToTime:(double)newSeekTime
{
	if ([self calculatedBitRate] == 0.0 || fileLength <= 0)
	{
		return;
	}
	
	//
	// Calculate the byte offset for seeking
	//
	seekByteOffset = dataOffset +
		(newSeekTime / self.duration) * (fileLength - dataOffset);
		
	//
	// Attempt to leave 1 useful packet at the end of the file (although in
	// reality, this may still seek too far if the file has a long trailer).
	//
	if (seekByteOffset > fileLength - 2 * packetBufferSize)
	{
		seekByteOffset = fileLength - 2 * packetBufferSize;
	}
	
	//
	// Store the old time from the audio queue and the time that we're seeking
	// to so that we'll know the correct time progress after seeking.
	//
	seekTime = newSeekTime;
	
	//
	// Attempt to align the seek with a packet boundary
	//
	double calculatedBitRate = [self calculatedBitRate];
	if (packetDuration > 0 &&
		calculatedBitRate > 0)
	{
		UInt32 ioFlags = 0;
		SInt64 packetAlignedByteOffset;
		SInt64 seekPacket = floor(newSeekTime / packetDuration);
		err = AudioFileStreamSeek(audioFileStream, seekPacket, &packetAlignedByteOffset, &ioFlags);
		if (!err && !(ioFlags & kAudioFileStreamSeekFlag_OffsetIsEstimated))
		{
			seekTime -= ((seekByteOffset - dataOffset) - packetAlignedByteOffset) * 8.0 / calculatedBitRate;
			seekByteOffset = packetAlignedByteOffset + dataOffset;
		}
	}

	//
	// Close the current read straem
	//
	if (stream)
	{
		CFReadStreamClose(stream);
		CFRelease(stream);
		stream = nil;
	}

	//
	// Stop the audio queue
	//
	self.state = AS_STOPPING;
	stopReason = AS_STOPPING_TEMPORARILY;
	err = AudioQueueStop(audioQueue, true);
	if (err)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_STOP_FAILED];
		return;
	}

	//
	// Re-open the file stream. It will request a byte-range starting at
	// seekByteOffset.
	//
	[self openReadStream];
}

//
// seekToTime:
//
// Attempts to seek to the new time. Will be ignored if the bitrate or fileLength
// are unknown.
//
// Parameters:
//    newTime - the time to seek to
//
- (void)seekToTime:(double)newSeekTime
{
	@synchronized(self)
	{
		seekWasRequested = YES;
		requestedSeekTime = newSeekTime;
	}
}

//
// progress
//
// returns the current playback progress. Will return zero if sampleRate has
// not yet been detected.
//
- (double)progress
{
	@synchronized(self)
	{
        if (sampleRate > 0 && (state == AS_STOPPING || ![self isFinishing]))
        {
            if (state != AS_PLAYING && state != AS_PAUSED && state != AS_BUFFERING && state != AS_STOPPING)
            {
                return lastProgress;
            }

			AudioTimeStamp queueTime;
			Boolean discontinuity;
			err = AudioQueueGetCurrentTime(audioQueue, NULL, &queueTime, &discontinuity);

			const OSStatus AudioQueueStopped = 0x73746F70; // 0x73746F70 is 'stop'
			if (err == AudioQueueStopped)
			{
				return lastProgress;
			}
			else if (err)
			{
				[self failWithErrorCode:AS_GET_AUDIO_TIME_FAILED];
			}

			double progress = seekTime + queueTime.mSampleTime / sampleRate;
			if (progress < 0.0)
			{
				progress = 0.0;
			}
			
			lastProgress = progress;
			return progress;
		}
	}
	
	return lastProgress;
}

//
// calculatedBitRate
//
// returns the bit rate, if known. Uses packet duration times running bits per
//   packet if available, otherwise it returns the nominal bitrate. Will return
//   zero if no useful option available.
//
- (double)calculatedBitRate
{
	if (packetDuration && processedPacketsCount > BitRateEstimationMinPackets)
	{
		double averagePacketByteSize = processedPacketsSizeTotal / processedPacketsCount;
		return 8.0 * averagePacketByteSize / packetDuration;
	}
	
	if (bitRate)
	{
		return (double)bitRate;
	}
	
	return 0;
}

//
// duration
//
// Calculates the duration of available audio from the bitRate and fileLength.
//
// returns the calculated duration in seconds.
//
- (double)duration
{
	double calculatedBitRate = [self calculatedBitRate];
	
	if (calculatedBitRate == 0 || fileLength == 0)
	{
		return 0.0;
	}
	
	return (fileLength - dataOffset) / (calculatedBitRate * 0.125);
}

//
// pause
//
// A togglable pause function.
//
- (void)pause
{
	@synchronized(self)
	{
		if (state == AS_PLAYING)
		{
			err = AudioQueuePause(audioQueue);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_PAUSE_FAILED];
				return;
			}
			self.state = AS_PAUSED;
		}
		else if (state == AS_PAUSED)
		{
			err = AudioQueueStart(audioQueue, NULL);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
				return;
			}
			self.state = AS_PLAYING;
		}
	}
}

//
// stop
//
// This method can be called to stop downloading/playback before it completes.
// It is automatically called when an error occurs.
//
// If playback has not started before this method is called, it will toggle the
// "isPlaying" property so that it is guaranteed to transition to true and
// back to false 
//
- (void)stop
{
    NSLog(@"");
	@synchronized(self)
	{
        
//        if (stream) {
//            CFReadStreamClose(stream);
//            CFRelease(stream);
//            stream = nil;
//        }

		if (audioQueue &&
			(state == AS_PLAYING || state == AS_PAUSED ||
				state == AS_BUFFERING || state == AS_WAITING_FOR_QUEUE_TO_START))
		{
			self.state = AS_STOPPING;
			stopReason = AS_STOPPING_USER_ACTION;
			err = AudioQueueStop(audioQueue, true);
			if (err)
			{
				[self failWithErrorCode:AS_AUDIO_QUEUE_STOP_FAILED];
				return;
			}
		}
		else if (state != AS_INITIALIZED)
		{
			self.state = AS_STOPPED;
			stopReason = AS_STOPPING_USER_ACTION;
		}
		seekWasRequested = NO;
	}
    
    while (state != AS_INITIALIZED)
	{
		[NSThread sleepForTimeInterval:0.1];
	}
	
}

//
// handleReadFromStream:eventType:
//
// Reads data from the network file stream into the AudioFileStream
//
// Parameters:
//    aStream - the network file stream
//    eventType - the event which triggered this method
//
- (void)handleReadFromStream:(CFReadStreamRef)aStream
	eventType:(CFStreamEventType)eventType
{
    
    //NSLog(@"");
    
	if (aStream != stream)
	{
		//
		// Ignore messages from old streams
		//
		return;
	}
	
	if (eventType == kCFStreamEventErrorOccurred)
	{
		[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
	}
	else if (eventType == kCFStreamEventEndEncountered)
	{
        
        NSLog(@"Stream End encountered");
        
        
		@synchronized(self)
		{
			if ([self isFinishing])
			{
				return;
			}
		}
		
		//
		// If there is a partially filled buffer, pass it to the AudioQueue for
		// processing
		//
		if (bytesFilled)
		{
			if (self.state == AS_WAITING_FOR_DATA)
			{
				//
				// Force audio data smaller than one whole buffer to play.
				//
				self.state = AS_FLUSHING_EOF;
			}
			[self enqueueBuffer];
		}

		@synchronized(self)
		{
			if (state == AS_WAITING_FOR_DATA)
			{
				[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
			}
			
			//
			// We left the synchronized section to enqueue the buffer so we
			// must check that we are !finished again before touching the
			// audioQueue
			//
			else if (![self isFinishing])
			{
				if (audioQueue)
				{
					//
					// Set the progress at the end of the stream
					//
					err = AudioQueueFlush(audioQueue);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_FLUSH_FAILED];
						return;
					}

					self.state = AS_STOPPING;
					stopReason = AS_STOPPING_EOF;
					err = AudioQueueStop(audioQueue, false);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_FLUSH_FAILED];
						return;
					}
				}
				else
				{
					self.state = AS_STOPPED;
					stopReason = AS_STOPPING_EOF;
				}
			}
		}
	}
    
	else if (eventType == kCFStreamEventHasBytesAvailable)
	{

        @synchronized(self)
		{
            if ([self isFinishing] || !CFReadStreamHasBytesAvailable(stream))
            {
                return;
            }
        }
        
        UInt8 bytes[_calculatedBufferSize];
        UInt8 bytesNoMetaData[_calculatedBufferSize];
        CFIndex length = CFReadStreamRead(stream, bytes, _calculatedBufferSize);
        CFIndex lengthNoMetaData = 0;
        
        //NSLog(@"BUFFERING length %li, lengthNoMetaData %li", length, lengthNoMetaData);
        
        if (length == -1)
		{
			NSLog(@"Buffer failed");
			return;
		}
        
        if (length > 0) {
            
            int streamStart = 0;
            
            // Read the HTTP response and get the meta data interval
            if (metaDataInterval == 0)
            {

                
                CFHTTPMessageRef myResponse = (CFHTTPMessageRef)CFReadStreamCopyProperty(stream, kCFStreamPropertyHTTPResponseHeader);
                UInt32 statusCode = CFHTTPMessageGetResponseStatusCode(myResponse);
                
                NSLog(@"Response: %@", myResponse);
                //CFStringRef myStatusLine = CFHTTPMessageCopyResponseStatusLine(myResponse);
                
                if (statusCode == 200)		// "OK" (this is true even for ICY)
                {
                    // check if this is a ICY 200 OK response
                    NSString *icyCheck = [[NSString alloc] initWithBytes:bytes length:10 encoding:NSUTF8StringEncoding];
                    if (icyCheck != nil && [icyCheck caseInsensitiveCompare:@"ICY 200 OK"] == NSOrderedSame)
                    {
                        foundIcyStart = YES;
                        //NSLog(@"ICY 200 OK");
                    }
                    else
                    {
                        // Not an ICY response
                        NSString *metaInt;
                        NSString *contentType;
                        NSString *icyBr;
                        metaInt = (__bridge  NSString *) CFHTTPMessageCopyHeaderFieldValue(myResponse, CFSTR("Icy-Metaint"));
                        contentType = (__bridge  NSString *) CFHTTPMessageCopyHeaderFieldValue(myResponse, CFSTR("Content-Type"));
                        icyBr = (__bridge  NSString *) CFHTTPMessageCopyHeaderFieldValue(myResponse, CFSTR("icy-br"));
                        
                        if (contentType)
                        {
                            // only if we haven't already set a content-type
                            if (!streamContentType)
                            {
                                //NSLog(@"Stream Content-Type: %@", contentType);
                                
                                streamContentType = contentType;
                                
                                AudioFileTypeID fileTypeHint = [AudioStreamer hintForContentType:streamContentType];
                                
                                if (audioFileStream) {
                                    if (fileTypeHint != _fileTypeHint) {
                                        
                                        _fileTypeHint = fileTypeHint;
                                        
                                        _codec = [AudioStreamer codecNameFromFileTypeHint:_fileTypeHint];
                                        [self restartAudioQueue];
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [delegate audioStreamerDetectedDifferentCodec:[AudioStreamer codecNameFromFileTypeHint:_fileTypeHint]];
                                        });
                                        
                                    }
                                }
                            }
                        }
                        
                        if (icyBr) {
                            
                            icyBr = [[icyBr componentsSeparatedByString:@","] objectAtIndex:0];
                            
                            //NSLog(@"Stream Bitrate: %@", icyBr);
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [delegate audioStreamerDetectedBitrate:icyBr];
                            });
                            
                            if (bitRate == 0)
                            {
                                bitRate = [icyBr intValue];
                            }
                            
                        }
                        
                        
                        
                        metaDataInterval = [metaInt intValue];
                        if (metaInt)
                        {
                            //NSLog(@"MetaInt: %@", metaInt);
                            parsedHeaders = YES;
                        }
                    }
                }
                else if (statusCode == 301 || statusCode == 302 || statusCode == 303 || statusCode == 307)
                {
                    NSLog(@"ERROR HTTP RESPONSE COCE: %li", statusCode);
                    // Redirect
                    
                    //myData.redirect = YES;
//					NSLog(@"Redirect to another URL.");
//					
//					NSString *escapedValue =
//					[(NSString *)CFURLCreateStringByAddingPercentEscapes(
//																		 nil,
//																		 CFHTTPMessageCopyHeaderFieldValue(myResponse, CFSTR("Location")),
//																		 NULL,
//																		 NULL,
//																		 kCFStringEncodingUTF8)
//					 autorelease];
//					
//					NSURL* redirectURL = [NSURL URLWithString:escapedValue];
//                    
//                    NSLog(@"New URL %@", redirectURL);
//                    
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [delegate audioStreamerRedirectsToURL:redirectURL];
//                    });
//                    
//                    // redirectURL
//                    
//					// alert interested parties
////					[myData redirectStreamError:myData.url];
////					myData->failed = YES;
                }
                else
                {
                    NSLog(@"ERROR HTTP RESPONSE COCE: %li", statusCode);
                    // Invalid
                    
                    NSLog(@"Error failed to open stream!");
//                    [self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
//                    return;
                }
            }
            
            if (foundIcyStart && !foundIcyEnd)
            {

                
                char c1 = '\0';
                char c2 = '\0';
                char c3 = '\0';
                char c4 = '\0';
                int lineStart = streamStart;
                while (YES)
                {
                    //NSLog(@"Strange Queue");
                    if (streamStart + 3 > length)
                    {
                        break;
                    }
                    
                    c1 = bytes[streamStart];
                    c2 = bytes[streamStart+1];
                    c3 = bytes[streamStart+2];
                    c4 = bytes[streamStart+3];
                    
                    if (c1 == '\r' && c2 == '\n')
                    {
                        // get the full string
                        NSString *fullString = [[NSString alloc] initWithBytes:bytes length:streamStart encoding:NSUTF8StringEncoding];
                        
                        // get the substring for this line
                        
                        NSString* line;
                        
                        int length = (streamStart-lineStart);
                        
                        if (length > ([fullString length] - lineStart)) {
                            
                            //NSLog(@"Alarm Stirng zu kurz %i < %i", length, ([fullString length] - lineStart));
                            length = ([fullString length] - lineStart);
                            
                            line = [fullString substringWithRange:NSMakeRange(lineStart, length)];
                            
                        } else {
                            
                            line = [fullString substringWithRange:NSMakeRange(lineStart, (streamStart-lineStart))];
                            
                        }
                        
                        //NSLog(@"Header Line: %@. Length: %d", line, [line length]);
                        
                        /*
                         icy-name:All Smooth Jazz -111 East Radio. Length: 40
                         icy-genre:Smooth Jazz. Length: 21
                         icy-url:http://www.allsmoothjazzradio.com. Length: 41
                         */
                        // check if this is icy-metaint
                        NSArray *lineItems = [line componentsSeparatedByString:@":"];
                        if ([lineItems count] > 1)
                        {
                            if ([[lineItems objectAtIndex:0] caseInsensitiveCompare:@"icy-metaint"] == NSOrderedSame)
                            {
                                metaDataInterval = [[lineItems objectAtIndex:1] intValue];
                                //NSLog(@"ICY MetaInt: %d", metaDataInterval);
                            }
                             else if ([[lineItems objectAtIndex:0] caseInsensitiveCompare:@"icy-br"] == NSOrderedSame)
                            {
                                uint32_t icybr = [[lineItems objectAtIndex:1] intValue];
                                if (bitRate == 0) {
                                    bitRate = icybr;
                                    //NSLog(@"ICY BR: %d", icybr);
                                    
                                    if (icybr != 0) {
                                        
                                        NSString* theBitRate = [NSString stringWithFormat:@"%d", icybr];
                                        
                                        //NSLog(@"Stream Bitrate second analyzer: %@", theBitRate);
                                        
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [delegate audioStreamerDetectedBitrate:theBitRate];
                                        });
                                        
                                    }
                                    
                                }
                            }
                            else if ([[lineItems objectAtIndex:0] caseInsensitiveCompare:@"Content-Type"] == NSOrderedSame)
                            {
                                //NSLog(@"ICY Stream Content-Type: %@", [lineItems objectAtIndex:1]);
                                // only if we haven't already set the content type
                                if (!self.streamContentType)
                                {
                                    self.streamContentType = [lineItems objectAtIndex:1];
                                    
                                    AudioFileTypeID fileTypeHint = [AudioStreamer hintForContentType:self.streamContentType];
                                    
                                    if (audioFileStream) {
                                        if (fileTypeHint != _fileTypeHint) {
                                            
                                            _fileTypeHint = fileTypeHint;
                                            _codec = [AudioStreamer codecNameFromFileTypeHint:_fileTypeHint];
                                            
                                            [self restartAudioQueue];
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                [delegate audioStreamerDetectedDifferentCodec:[AudioStreamer codecNameFromFileTypeHint:_fileTypeHint]];
                                            });
                                            
                                            
                                        }
                                    }
                                    
                                    
                                    
                                    // if this is not an mp3 stream we need to restart the audio queue
                                    //                                if ([myData.streamContentType caseInsensitiveCompare:@"audio/mpeg"] != NSOrderedSame)
                                    //                                {
                                    //                                    [myData restartAudioQueue];
                                    //                                }
                                }
                            } else if ([[lineItems objectAtIndex:0] caseInsensitiveCompare:@"icy-name"] == NSOrderedSame) {
                                
                                NSString* icyName = [line stringByReplacingOccurrencesOfString:@"icy-name:" withString:@""];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [delegate audioStreamerUpdatedICYName:icyName];
                                });
                                
                                
                            } else if ([[lineItems objectAtIndex:0] caseInsensitiveCompare:@"icy-url"] == NSOrderedSame) {
                                
                                NSString* icyURL = [line stringByReplacingOccurrencesOfString:@"icy-url:" withString:@""];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [delegate audioStreamerUpdatedICYURL:icyURL];
                                });
                                
                            }
                            
                        } 
                        
                        // this is the end of a line, the new line starts in 2
                        lineStart = streamStart+2; // (c3)
                        
                        if (c3 == '\r' && c4 == '\n')
                        {
                            self.foundIcyEnd = YES;
                            break;
                        }
                    }
                    
                    streamStart++;
                } // end while
                
                if (self.foundIcyEnd)
                {
                    streamStart = streamStart + 4;
                    //NSLog(@"Found End.");
                    parsedHeaders = YES;
                }
            }
            
            if (parsedHeaders)
            {

                //NSData* blockData = [NSData dataWithBytes:&bytes length:kAQDefaultBufSize];
                
                //dispatch_async(backGroundQueue, ^{
                
                for (int i=streamStart; i < length; i++)
                {
                    //                    UInt8 blockBytes[kAQDefaultBufSize];
                    //                    memcpy(blockBytes, blockData.bytes, kAQDefaultBufSize);
                    
                    
                    // is this a metadata byte?
                    if (metaDataBytesRemaining > 0)
                    {
                        if (metaDataString == nil) {
                            metaDataString = [NSMutableData new];
                        }
                        
                        //NSLog(@"meta: %c", bytes[i]);
                        UInt8 metaByte = bytes[i];
                        [metaDataString appendBytes:&metaByte length:1];
                        
                        metaDataBytesRemaining -= 1;
                        
                        if (metaDataBytesRemaining == 0)
                        {
                            
                            NSString* metaString = [[NSString alloc] initWithBytes:metaDataString.bytes length:metaDataString.length encoding:NSUTF8StringEncoding];
                            //NSLog(@"MetaData: %@.", metaString);
                            
                            if (metaString != nil && ![metaString isEqualToString:@""]) {
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [delegate audioStreamerUpdatedMetaData:metaString];
                                });
                                
                                metaDataString = nil;
                                
                            }
                            
                            dataBytesRead = 0;
                        }
                        continue;
                    }
                    
                    // is this the interval byte?
                    if (metaDataInterval > 0 && dataBytesRead == metaDataInterval)
                    {
                        metaDataBytesRemaining = bytes[i] * 16;
                        //NSLog(@"Found interval. Interval: %d, Meta Length: %d", metaDataInterval, metaDataBytesRemaining);
                        
                        
                        
                        if (metaDataBytesRemaining == 0)
                        {
                            dataBytesRead = 0;
                        }
                        else
                        {
                            //NSLog(@"Found interval. Meta Length: %d", metaDataBytesRemaining);
                        }
                        
                        continue;
                    }
                    
                    // this is a data byte
                    dataBytesRead += 1;
                    
                    // copy the data to the new buffer
                    bytesNoMetaData[lengthNoMetaData] = bytes[i];
                    lengthNoMetaData += 1;
                } // end for
                //            });
                
            }	// end if parsedHeaders
        }
        
        //NSLog(@"BUFFERING length %li, lengthNoMetaData %li", length, lengthNoMetaData);
        
		if (!audioFileStream)
        {
            AudioFileTypeID fileTypeHint;
            if (streamContentType != nil) {
                
                //NSLog(@"Using streamContentType %@ for file type guess", streamContentType);
                
                fileTypeHint = [AudioStreamer hintForContentType:streamContentType];
                
                if (_codec != nil) {
                    if (fileTypeHint != [AudioStreamer hintForFileExtension:_codec]) {
                        [delegate audioStreamerDetectedDifferentCodec:[AudioStreamer codecNameFromFileTypeHint:fileTypeHint]];
                        return;
                    }
                }
                
            } else if (_codec != nil) {
                
                //NSLog(@"Using codec from database info %@", _codec);
                
                fileTypeHint = [AudioStreamer hintForFileExtension:_codec];
                
            } else {
                
                //NSLog(@"Using codec from file extension %@", [[url path] pathExtension]);
                
                fileTypeHint = [AudioStreamer hintForFileExtension:[[url path] pathExtension]];
            }
            
            _fileTypeHint = fileTypeHint;
            
            
            //NSLog(@"Codec set to %@, trying to start Audio", [AudioStreamer codecNameFromFileTypeHint:_fileTypeHint]);
            
            
            err = AudioFileStreamOpen((__bridge void *)(self), ASPropertyListenerProc, ASPacketsProc,
                                      fileTypeHint, &audioFileStream);
            
            if (err)
            {
                NSLog(@"Error failed to open stream!");
                [self failWithErrorCode:AS_FILE_STREAM_OPEN_FAILED];
                return;
            }
        }
		
		@synchronized(self)
		{

			
			if (length == -1)
			{
				[self failWithErrorCode:AS_AUDIO_DATA_NOT_FOUND];
				return;
			}
			
			if (length == 0)
			{
				return;
			}
		}
        
		if (discontinuous)
		{
            //err = AudioFileStreamParseBytes(audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
            
            if (lengthNoMetaData > 0)
            {
                bytesFromStream += lengthNoMetaData;
                err = AudioFileStreamParseBytes(audioFileStream, lengthNoMetaData, bytesNoMetaData, kAudioFileStreamParseFlag_Discontinuity);
            } else {
                bytesFromStream += length;
                err = AudioFileStreamParseBytes(audioFileStream, length, bytes, kAudioFileStreamParseFlag_Discontinuity);
            }
			
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
		}
		else
		{
            if (lengthNoMetaData > 0)
            {
                bytesFromStream += lengthNoMetaData;
                //NSLog(@"Parsing bytes without meta data");
                err = AudioFileStreamParseBytes(audioFileStream, lengthNoMetaData, bytesNoMetaData, 0);
            } else {
                bytesFromStream += length;
                err = AudioFileStreamParseBytes(audioFileStream, length, bytes, 0);
            }
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_PARSE_BYTES_FAILED];
				return;
			}
		}
	}
    
    //NSLog(@"Bytes from stream %i", bytesFromStream);
    
}


- (void)handleAudioQueueProcessingData:(UInt32)inNumberFrames outNumberOfFrames:(UInt32*)outNumberFrames audioBufferList:(AudioBufferList*)ioData {
    
//    NSLog(@"inNumberFrames %li outNumberOfFrames %li", inNumberFrames, *outNumberFrames);
//    
//    NSLog(@"Number of Buffers: %li", ioData->mNumberBuffers);
    
//    if (VISUALIZATIONS) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [[FDIVisualizerContainerViewController sharedInstance] processAudioBuffer:ioData withSampleRate:sampleRate];
//        });
//    }
    
    
    
}



//
// enqueueBuffer
//
// Called from ASPacketsProc and connectionDidFinishLoading to pass filled audio
// bufffers (filled by ASPacketsProc) to the AudioQueue for playback. This
// function does not return until a buffer is idle for further filling or
// the AudioQueue is stopped.
//
// This function is adapted from Apple's example in AudioFileStreamExample with
// CBR functionality added.
//
- (void)enqueueBuffer
{
	@synchronized(self)
	{
		if ([self isFinishing] || stream == 0)
		{
			return;
		}
		
		inuse[fillBufferIndex] = true;		// set in use flag
		buffersUsed++;
        
        

		// enqueue buffer
		AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
		fillBuf->mAudioDataByteSize = bytesFilled;
		
		if (packetsFilled)
		{
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, packetsFilled, packetDescs);
		}
		else
		{
			err = AudioQueueEnqueueBuffer(audioQueue, fillBuf, 0, NULL);
		}
		
		if (err)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_ENQUEUE_FAILED];
			return;
		}

		
		if (state == AS_BUFFERING ||
			state == AS_WAITING_FOR_DATA ||
			state == AS_FLUSHING_EOF ||
			(state == AS_STOPPED && stopReason == AS_STOPPING_TEMPORARILY))
		{
			//
			// Fill all the buffers before starting. This ensures that the
			// AudioFileStream stays a small amount ahead of the AudioQueue to
			// avoid an audio glitch playing streaming files on iPhone SDKs < 3.0
			//
			if (state == AS_FLUSHING_EOF || buffersUsed == kNumAQBufs - 1)
			{
				if (self.state == AS_BUFFERING)
				{
					err = AudioQueueStart(audioQueue, NULL);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
					self.state = AS_PLAYING;
				}
				else
				{
					self.state = AS_WAITING_FOR_QUEUE_TO_START;

					err = AudioQueueStart(audioQueue, NULL);
					if (err)
					{
						[self failWithErrorCode:AS_AUDIO_QUEUE_START_FAILED];
						return;
					}
				}
			}
		}

		// go to next buffer
		if (++fillBufferIndex >= kNumAQBufs) fillBufferIndex = 0;
		bytesFilled = 0;		// reset bytes filled
		packetsFilled = 0;		// reset packets filled
	}

	// wait until next buffer is not in use
	pthread_mutex_lock(&queueBuffersMutex); 
	while (inuse[fillBufferIndex])
	{
		pthread_cond_wait(&queueBufferReadyCondition, &queueBuffersMutex);
	}
	pthread_mutex_unlock(&queueBuffersMutex);
}

//
// createQueue
//
// Method to create the AudioQueue from the parameters gathered by the
// AudioFileStream.
//
// Creation is deferred to the handling of the first audio packet (although
// it could be handled any time after kAudioFileStreamProperty_ReadyToProducePackets
// is true).
//
- (void)createQueue
{
	sampleRate = asbd.mSampleRate;
	packetDuration = asbd.mFramesPerPacket / sampleRate;
	
	// create the audio queue
	err = AudioQueueNewOutput(&asbd, ASAudioQueueOutputCallback, (__bridge void *)(self), NULL, NULL, 0, &audioQueue);
	if (err)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_CREATION_FAILED];
		return;
	}
    
    /*
     anASBD.mFormatFlags = kAudioFormatFlagIsSignedInteger |
     kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked;
     anASBD.mSampleRate = 44100;
     anASBD.mChannelsPerFrame = 2;
     anASBD.mFramesPerPacket = 1;
     anASBD.mBytesPerPacket=anASBD.mChannelsPerFrame * sizeof (SInt16);
     anASBD.mBytesPerFrame =anASBD.mChannelsPerFrame * sizeof (SInt16);
     anASBD.mBitsPerChannel = 16;
     */
    
    outProcessingFormat.mSampleRate = 44100;
    outProcessingFormat.mFormatID = kAudioFormatLinearPCM;
    outProcessingFormat.mChannelsPerFrame = 2;
    outProcessingFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger |
    kAudioFormatFlagIsBigEndian | kAudioFormatFlagIsPacked;
    outProcessingFormat.mBytesPerPacket = outProcessingFormat.mChannelsPerFrame * sizeof (SInt16);
    outProcessingFormat.mBytesPerFrame = outProcessingFormat.mChannelsPerFrame * sizeof (SInt16);
    outProcessingFormat.mFramesPerPacket = 1;
    outProcessingFormat.mBitsPerChannel = 16;
    
    UInt32 maxSamples = 2048 * 2;
	
    OSStatus specialErr = AudioQueueProcessingTapNew(audioQueue, ASAudioQueueProcessingTapCallback, (__bridge void *)(self), kAudioQueueProcessingTap_Siphon|kAudioQueueProcessingTap_PreEffects, &maxSamples, &outProcessingFormat, &(audioQueueTap));
    
    if (specialErr) {
        NSLog(@"Error Creating Tap: %li", specialErr);
    }
    
	// start the queue if it has not been started already
	// listen to the "isRunning" property
	err = AudioQueueAddPropertyListener(audioQueue, kAudioQueueProperty_IsRunning, ASAudioQueueIsRunningCallback, (__bridge void *)(self));
	if (err)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_ADD_LISTENER_FAILED];
		return;
	}
	
	// get the packet size if it is available
	UInt32 sizeOfUInt32 = sizeof(UInt32);
	err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_PacketSizeUpperBound, &sizeOfUInt32, &packetBufferSize);
	if (err || packetBufferSize == 0)
	{
		err = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MaximumPacketSize, &sizeOfUInt32, &packetBufferSize);
		if (err || packetBufferSize == 0)
		{
			// No packet size available, just use the default
			packetBufferSize = _calculatedBufferSize;
		}
	}

	// allocate audio queue buffers
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		err = AudioQueueAllocateBuffer(audioQueue, packetBufferSize, &audioQueueBuffer[i]);
		if (err)
		{
			[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_ALLOCATION_FAILED];
			return;
		}
	}

	// get the cookie size
	UInt32 cookieSize;
	Boolean writable;
	OSStatus ignorableError;
	ignorableError = AudioFileStreamGetPropertyInfo(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, &writable);
	if (ignorableError)
	{
		return;
	}

	// get the cookie data
	void* cookieData = calloc(1, cookieSize);
	ignorableError = AudioFileStreamGetProperty(audioFileStream, kAudioFileStreamProperty_MagicCookieData, &cookieSize, cookieData);
	if (ignorableError)
	{
		return;
	}

	// set the cookie on the queue.
	ignorableError = AudioQueueSetProperty(audioQueue, kAudioQueueProperty_MagicCookie, cookieData, cookieSize);
	free(cookieData);
	if (ignorableError)
	{
		return;
	}
}

//
// handlePropertyChangeForFileStream:fileStreamPropertyID:ioFlags:
//
// Object method which handles implementation of ASPropertyListenerProc
//
// Parameters:
//    inAudioFileStream - should be the same as self->audioFileStream
//    inPropertyID - the property that changed
//    ioFlags - the ioFlags passed in
//
- (void)handlePropertyChangeForFileStream:(AudioFileStreamID)inAudioFileStream
	fileStreamPropertyID:(AudioFileStreamPropertyID)inPropertyID
	ioFlags:(UInt32 *)ioFlags
{
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (inPropertyID == kAudioFileStreamProperty_ReadyToProducePackets)
		{
			discontinuous = true;
		}
		else if (inPropertyID == kAudioFileStreamProperty_DataOffset)
		{
			SInt64 offset;
			UInt32 offsetSize = sizeof(offset);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataOffset, &offsetSize, &offset);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
			dataOffset = offset;
			
			if (audioDataByteCount)
			{
				fileLength = dataOffset + audioDataByteCount;
			}
		}
		else if (inPropertyID == kAudioFileStreamProperty_AudioDataByteCount)
		{
			UInt32 byteCountSize = sizeof(UInt64);
			err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_AudioDataByteCount, &byteCountSize, &audioDataByteCount);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
			fileLength = dataOffset + audioDataByteCount;
		}
		else if (inPropertyID == kAudioFileStreamProperty_DataFormat)
		{
			if (asbd.mSampleRate == 0)
			{
				UInt32 asbdSize = sizeof(asbd);
				
				// get the stream format.
				err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_DataFormat, &asbdSize, &asbd);
				if (err)
				{
					[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
					return;
				}
			}
		}
		else if (inPropertyID == kAudioFileStreamProperty_FormatList)
		{
			Boolean outWriteable;
			UInt32 formatListSize;
			err = AudioFileStreamGetPropertyInfo(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, &outWriteable);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}
			
			AudioFormatListItem *formatList = malloc(formatListSize);
	        err = AudioFileStreamGetProperty(inAudioFileStream, kAudioFileStreamProperty_FormatList, &formatListSize, formatList);
			if (err)
			{
				[self failWithErrorCode:AS_FILE_STREAM_GET_PROPERTY_FAILED];
				return;
			}

			for (int i = 0; i * sizeof(AudioFormatListItem) < formatListSize; i += sizeof(AudioFormatListItem))
			{
				AudioStreamBasicDescription pasbd = formatList[i].mASBD;
		
				if (pasbd.mFormatID == kAudioFormatMPEG4AAC_HE ||
					pasbd.mFormatID == kAudioFormatMPEG4AAC_HE_V2)
				{
					//
					// We've found HE-AAC, remember this to tell the audio queue
					// when we construct it.
					//
#if !TARGET_IPHONE_SIMULATOR
					asbd = pasbd;
#endif
					break;
				}                                
			}
			free(formatList);
		}
		else
		{
//			NSLog(@"Property is %c%c%c%c",
//				((char *)&inPropertyID)[3],
//				((char *)&inPropertyID)[2],
//				((char *)&inPropertyID)[1],
//				((char *)&inPropertyID)[0]);
		}
	}
}

//
// handleAudioPackets:numberBytes:numberPackets:packetDescriptions:
//
// Object method which handles the implementation of ASPacketsProc
//
// Parameters:
//    inInputData - the packet data
//    inNumberBytes - byte size of the data
//    inNumberPackets - number of packets in the data
//    inPacketDescriptions - packet descriptions
//
- (void)handleAudioPackets:(const void *)inInputData
	numberBytes:(UInt32)inNumberBytes
	numberPackets:(UInt32)inNumberPackets
	packetDescriptions:(AudioStreamPacketDescription *)inPacketDescriptions;
{
    //NSLog(@"");
    
	@synchronized(self)
	{
		if ([self isFinishing])
		{
			return;
		}
		
		if (bitRate == 0)
		{
			//
			// m4a and a few other formats refuse to parse the bitrate so
			// we need to set an "unparseable" condition here. If you know
			// the bitrate (parsed it another way) you can set it on the
			// class if needed.
			//
			bitRate = ~0;
		}
		
		// we have successfully read the first packests from the audio stream, so
		// clear the "discontinuous" flag
		if (discontinuous)
		{
			discontinuous = false;
		}
		
		if (!audioQueue)
		{
			[self createQueue];
		}
	}

	// the following code assumes we're streaming VBR data. for CBR data, the second branch is used.
	if (inPacketDescriptions)
	{
		for (int i = 0; i < inNumberPackets; ++i)
		{
			SInt64 packetOffset = inPacketDescriptions[i].mStartOffset;
			SInt64 packetSize   = inPacketDescriptions[i].mDataByteSize;
			size_t bufSpaceRemaining;
			
			if (processedPacketsCount < BitRateEstimationMaxPackets)
			{
				processedPacketsSizeTotal += packetSize;
				processedPacketsCount += 1;
			}
			
			@synchronized(self)
			{
				// If the audio was terminated before this point, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				if (packetSize > packetBufferSize)
				{
					[self failWithErrorCode:AS_AUDIO_BUFFER_TOO_SMALL];
				}

				bufSpaceRemaining = packetBufferSize - bytesFilled;
			}

			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			if (bufSpaceRemaining < packetSize)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				//
				// If there was some kind of issue with enqueueBuffer and we didn't
				// make space for the new audio data then back out
				//
				if (bytesFilled + packetSize > packetBufferSize)
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)inInputData + packetOffset, packetSize);
                
				// fill out packet description
				packetDescs[packetsFilled] = inPacketDescriptions[i];
				packetDescs[packetsFilled].mStartOffset = bytesFilled;
				// keep track of bytes filled and packets filled
				bytesFilled += packetSize;
				packetsFilled += 1;
			}
			
			// if that was the last free packet description, then enqueue the buffer.
			size_t packetsDescsRemaining = kAQMaxPacketDescs - packetsFilled;
			if (packetsDescsRemaining == 0) {
				[self enqueueBuffer];
			}
		}	
	}
	else
	{
		size_t offset = 0;
		while (inNumberBytes)
		{
			// if the space remaining in the buffer is not enough for this packet, then enqueue the buffer.
			size_t bufSpaceRemaining = _calculatedBufferSize - bytesFilled;
			if (bufSpaceRemaining < inNumberBytes)
			{
				[self enqueueBuffer];
			}
			
			@synchronized(self)
			{
				// If the audio was terminated while waiting for a buffer, then
				// exit.
				if ([self isFinishing])
				{
					return;
				}
				
				bufSpaceRemaining = _calculatedBufferSize - bytesFilled;
				size_t copySize;
				if (bufSpaceRemaining < inNumberBytes)
				{
					copySize = bufSpaceRemaining;
				}
				else
				{
					copySize = inNumberBytes;
				}

				// If there was some kind of issue with enqueueBuffer and we didn't
				// make space for the new audio data then back out
				if (bytesFilled > packetBufferSize)
				{
					return;
				}
				
				// copy data to the audio queue buffer
				AudioQueueBufferRef fillBuf = audioQueueBuffer[fillBufferIndex];
				memcpy((char*)fillBuf->mAudioData + bytesFilled, (const char*)(inInputData + offset), copySize);

				// keep track of bytes filled and packets filled
				bytesFilled += copySize;
				packetsFilled = 0;
				inNumberBytes -= copySize;
				offset += copySize;
			}
		}
	}
}

//
// handleBufferCompleteForQueue:buffer:
//
// Handles the buffer completetion notification from the audio queue
//
// Parameters:
//    inAQ - the queue
//    inBuffer - the buffer
//
- (void)handleBufferCompleteForQueue:(AudioQueueRef)inAQ
	buffer:(AudioQueueBufferRef)inBuffer
{
    
    bytesInPackets += inBuffer->mAudioDataByteSize;
    
    //NSLog(@"Bytes in packets %i", bytesInPackets);

	unsigned int bufIndex = -1;
	for (unsigned int i = 0; i < kNumAQBufs; ++i)
	{
		if (inBuffer == audioQueueBuffer[i])
		{
			bufIndex = i;
			break;
		}
	}
	
	if (bufIndex == -1)
	{
		[self failWithErrorCode:AS_AUDIO_QUEUE_BUFFER_MISMATCH];
		pthread_mutex_lock(&queueBuffersMutex);
		pthread_cond_signal(&queueBufferReadyCondition);
		pthread_mutex_unlock(&queueBuffersMutex);
		return;
	}
	
	// signal waiting thread that the buffer is free.
	pthread_mutex_lock(&queueBuffersMutex);
	inuse[bufIndex] = false;
	buffersUsed--;

//
//  Enable this logging to measure how many buffers are queued at any time.
//
#if LOG_QUEUED_BUFFERS
	NSLog(@"Queued buffers: %ld", buffersUsed);
#endif
	
	pthread_cond_signal(&queueBufferReadyCondition);
	pthread_mutex_unlock(&queueBuffersMutex);
}

//
// handlePropertyChangeForQueue:propertyID:
//
// Implementation for ASAudioQueueIsRunningCallback
//
// Parameters:
//    inAQ - the audio queue
//    inID - the property ID
//
- (void)handlePropertyChangeForQueue:(AudioQueueRef)inAQ
	propertyID:(AudioQueuePropertyID)inID
{
	
	@synchronized(self)
	{
		if (inID == kAudioQueueProperty_IsRunning)
		{
			if (state == AS_STOPPING)
			{
				self.state = AS_STOPPED;
			}
			else if (state == AS_WAITING_FOR_QUEUE_TO_START)
			{
				//
				// Note about this bug avoidance quirk:
				//
				// On cleanup of the AudioQueue thread, on rare occasions, there would
				// be a crash in CFSetContainsValue as a CFRunLoopObserver was getting
				// removed from the CFRunLoop.
				//
				// After lots of testing, it appeared that the audio thread was
				// attempting to remove CFRunLoop observers from the CFRunLoop after the
				// thread had already deallocated the run loop.
				//
				// By creating an NSRunLoop for the AudioQueue thread, it changes the
				// thread destruction order and seems to avoid this crash bug -- or
				// at least I haven't had it since (nasty hard to reproduce error!)
				//
				[NSRunLoop currentRunLoop];

				self.state = AS_PLAYING;
			}
			else
			{
				NSLog(@"AudioQueue changed state in unexpected way.");
			}
		}
	}
	
}

#if TARGET_OS_IPHONE
//
// handleInterruptionChangeForQueue:propertyID:
//
// Implementation for ASAudioQueueInterruptionListener
//
// Parameters:
//    inAQ - the audio queue
//    inID - the property ID
//
- (void)handleInterruptionChangeToState:(AudioQueuePropertyID)inInterruptionState 
{
	if (inInterruptionState == kAudioSessionBeginInterruption)
	{ 
		if ([self isPlaying]) {
			[self pause];
			
			pausedByInterruption = YES; 
		} 
	}
	else if (inInterruptionState == kAudioSessionEndInterruption) 
	{
		AudioSessionSetActive( true );
		
		if ([self isPaused] && pausedByInterruption) {
			[self pause]; // this is actually resume
			
			pausedByInterruption = NO; // this is redundant 
		}
	}
}
#endif


- (void)setVolume:(float)Level
{
    
    OSStatus errorMsg = AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, Level);
    
    if (errorMsg) {
        NSLog(@"AudioQueueSetParameter returned %ld when setting the volume.", errorMsg);
    }
    
}

- (float)volume {
    
    float volume = 0;;
    
    OSStatus errorMsg = AudioQueueGetParameter(audioQueue, kAudioQueueParam_Volume, &volume);
    
    if (errorMsg) {
        NSLog(@"AudioQueueSetParameter returned %ld when setting the volume.", errorMsg);
    }
    
    return volume;
    
}


// Restart Stream if new contentType is set


- (void)resetAudioQueue
{
    
    NSLog(@"");
    
	OSStatus theErr = AudioFileStreamClose(audioFileStream);
	
	// Stop the Audio Queue
	theErr = AudioQueueStop(audioQueue, true);
    
	theErr = AudioQueueReset(audioQueue);
	
	for (int i = 0; i < kNumAQBufs; ++i) {
        AudioQueueFreeBuffer(audioQueue, audioQueueBuffer[i]);
	}
    
}

- (void)restartAudioQueue
{
    
    NSLog(@"");
    
	[self resetAudioQueue];
	
	// create an audio file stream parser
	OSStatus theErr = AudioFileStreamOpen((__bridge void *)(self), ASPropertyListenerProc, ASPacketsProc,
									   _fileTypeHint, &audioFileStream);
    
    if (theErr) {
        
    }
    
}


@end
