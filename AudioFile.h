//
//  AudioFile.h
//  AudioUnitTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Vectorform, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AudioUnit/AudioUnit.h>

@interface AudioFile : NSObject {
	
@private
	AudioStreamBasicDescription audioFormat;
	AudioUnitSampleType			*audioData;
	UInt64						numFrames;
	UInt32						sampleNum;
	NSString*					fileName;
	int							audioIndex;
	int							busIndex;
	BOOL						isPlaying;
	BOOL						isPaused;
	BOOL						open;
	
}

#pragma mark --- Properties ---
@property (readwrite) AudioStreamBasicDescription 	audioFormat;
@property (readwrite) AudioUnitSampleType			*audioData;
@property (readwrite) UInt64						numFrames;
@property (readwrite) UInt32						sampleNum;
@property (readwrite) BOOL							isPlaying;
@property (readwrite) BOOL							isPaused;
@property (readwrite) BOOL							open;
@property (nonatomic, retain)  NSString*			fileName;
@property (readwrite) int							audioIndex;
@property (readwrite) int							busIndex;

#pragma mark --- Instance Methods ---
- (id)initWithPath:(NSString *)path andIndex:(int)index;
- (void)play;
- (void)stop;
- (void)pause;
- (void)unpause;
- (void)closeFile;

@end
