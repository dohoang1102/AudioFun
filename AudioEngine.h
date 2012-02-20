//
//  AudioEngine.h
//  AudioUnitTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Kevin Vitale. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudioTypes.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "AudioFile.h"

#define kOutputBus 0

static OSStatus PlaybackCallback(void *inRefCon,
								 AudioUnitRenderActionFlags *ioActionFlags,
								 const AudioTimeStamp *inTimeStamp,
								 UInt32 inBusNumber,
								 UInt32 inNumberFrames,
								 AudioBufferList *ioData) {
	
	AudioFile *audioFile 	= (AudioFile *)inRefCon;
    
	if(audioFile.isPlaying) {
		UInt32 bufSamples 		= audioFile.numFrames;
		AudioUnitSampleType *in = audioFile.audioData;
		
		AudioUnitSampleType *outA = (AudioUnitSampleType *)ioData->mBuffers[0].mData;
		AudioUnitSampleType *outB = (AudioUnitSampleType *)ioData->mBuffers[1].mData;
		
		UInt32 sample = audioFile.sampleNum;
		for (UInt32 i = 0; i < inNumberFrames; ++i) {
			
			/*
			if (inBusNumber == 0) {
				outA[i] = in[sample++];
				outB[i] = 0;
			} else {
				outA[i] = 0;
				outB[i] = in[sample++];
			}
			 */
			
			outA[i] = in[sample++];
			//outB[i] = in[sample++];
			outB[i] = outA[i];
			if (sample >= bufSamples) sample = 0;
		}
		audioFile.sampleNum = sample;
		//printf("bus %i sample %i\n", (int)inBusNumber, (int)sample);
	}

    
	return noErr;
}

///////////////////////////////////////////////////////////////////////////

@interface AudioEngine : NSObject {

@private
	NSMutableArray *audioFilePaths;
	AudioUnit 		audioMixer;
	AUGraph 		audioGraph;
	AUNode			mixerNode;
	AUNode			outputNode;
	
	UInt32 			totalNumBuses;
	UInt32			busCounter;
	UInt32			busToRemove;
	
	AudioFile		*audioFile1;
	AudioFile		*audioFile2;
	
	int				currentAuxFile;
	
	NSOperationQueue *queue;
	
@private
	NSMutableArray *audioFiles;
}

#pragma mark --- Class Methods ---
+ (AudioEngine *)instance;
+ (void)shutdown;

#pragma mark --- Instance Methods ---

#pragma mark Helper Functions
- (OSStatus)addOutputNodeToGraph;
- (OSStatus)addMixerNodeToGraph;
- (void)restartAudioFiles;
- (void)resumeAllPlayback;
- (void)pauseAllPlayback;
- (void)logActiveBuses;
#pragma mark Maintenance Functions
- (OSStatus)startEngine;
- (OSStatus)stopEngine;
- (BOOL)isRunning;
#pragma mark Setter Functions
- (OSStatus)setOutputToStereo;
- (OSStatus)setNumberOfAudioBuses:(int)numOfBuses;
#pragma mark Audio File Functions
- (void)playAuxiliaryAudioFile:(NSString *)fileName;
- (void)stopAuxiliaryAudioFile;
- (void)stopAllRunningAudioFiles;
- (AudioFile *)audioFileForID:(int)audioID;
- (NSString *)fileNameForAudioID:(int)index;



#pragma mark --- Properties ---
@property (retain)	  NSOperationQueue			*queue;
@property (readwrite) UInt32					busToRemove;
@property (readwrite) UInt32					busCounter;
@property (nonatomic, retain) NSMutableArray 	*audioFilePaths;
@property (nonatomic, readonly) NSArray 	*audioFileNames;
@property (nonatomic, retain) NSMutableArray 	*audioFiles;
@property (readwrite) UInt32					totalNumBuses;
@property (readwrite) AUNode					mixerNode;
@property (readwrite) AUNode					outputNode;
@property (readwrite) AudioUnit 				audioMixer;
@property (readwrite) AUGraph					audioGraph;

@end
