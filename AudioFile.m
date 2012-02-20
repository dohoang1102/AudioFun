//
//  AudioFile.m
//  AudioUnitTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Vectorform, LLC. All rights reserved.
//

#import "AudioFile.h"
#import "AudioEngine.h"

const Float64 kGraphSampleRate = 22050;

@implementation AudioFile
@synthesize audioFormat;
@synthesize fileName;
@synthesize numFrames,
			sampleNum;
@synthesize audioIndex;
@synthesize isPlaying,
			isPaused;
@synthesize open;
@synthesize busIndex;

- (id)initWithPath:(NSString *)path andIndex:(int)index{
	if(self = [super init]) {
		
		if (!open) {
			
			open 			= YES;
			busIndex 		= -1;
			isPlaying 		= NO;
			isPaused 		= NO;
			
			AudioFileID		mAudioFile;
			OSStatus status = noErr;
			
			// Clear out the format
			memset (&audioFormat, 0, sizeof (audioFormat));
			
			self.audioIndex 	= index;
			self.fileName 		= [[path pathComponents] lastObject];
			
			// Create an CoreFoundation URL version
			CFURLRef sndFileURL = (CFURLRef)[NSURL fileURLWithPath:path];
			
			NSLog(@"(AudioFile.m) Loading file from disk...");
			
			// Opening files through this is so much easier than ExtAudioOpenURL...
			status = AudioFileOpenURL(sndFileURL, 
									  kAudioFileReadPermission, 
									  0, 
									  &mAudioFile);
			
			if(status != noErr) {
				NSLog(@"(AudioFile.m) Failed to Open File %@", fileName);
				return nil;
			}
			
			
			UInt32 propSize = sizeof(audioFormat);
			status = AudioFileGetProperty(mAudioFile, 
										 kAudioFilePropertyDataFormat, 
										 &propSize, 
										 &audioFormat);

			if(status != noErr) {
				NSLog(@"(AudioFile.m) Failed to Get File Data Format for %@", fileName);
				return nil;
			}
			
			// Close the AudioID (AudioID's are usually used for AudioQueueServices...)
			AudioFileClose(mAudioFile);
			
			ExtAudioFileRef xafref 			= 0;
			ExtAudioFileOpenURL(sndFileURL, &xafref);
			
			audioFormat.mFormatID 			= kAudioFormatLinearPCM;
			audioFormat.mSampleRate			= kGraphSampleRate;
			audioFormat.mFormatFlags 		= kAudioFormatFlagsCanonical | (kAudioUnitSampleFractionBits << kLinearPCMFormatFlagsSampleFractionShift);
			audioFormat.mChannelsPerFrame 	= 1;
			audioFormat.mFramesPerPacket 	= 1;
			audioFormat.mBitsPerChannel 	= 8 * sizeof(AudioUnitSampleType);
			audioFormat.mBytesPerPacket 	= sizeof(AudioUnitSampleType);
			audioFormat.mBytesPerFrame 		= sizeof(AudioUnitSampleType);
			
			propSize = sizeof(audioFormat);
			status = ExtAudioFileSetProperty(xafref, 
											 kExtAudioFileProperty_ClientDataFormat, 
											 propSize, 
											 &audioFormat);
			if(status != noErr) {
				NSLog(@"(AudioFile.m) Failed to Set Client Data Format for %@", fileName);
				return nil;
			}
			
			 // Get the file's length in sample frames
			numFrames 	= 0;
			propSize 	= sizeof(numFrames);
			status = ExtAudioFileGetProperty(xafref, 
											 kExtAudioFileProperty_FileLengthFrames, 
											 &propSize, 
											 &numFrames);
			
			if(status != noErr) {
				NSLog(@"(AudioFile.m) Failed to Get Length in Samples for %@", fileName);
				return nil;
			}
			
			//numFrames = (UInt32)(numFrames * 4);
			
			//UInt32 samples = numFrames * audioFormat.mChannelsPerFrame;
			audioData = (AudioUnitSampleType *)calloc(numFrames, sizeof(AudioUnitSampleType));
			sampleNum = 0;
			
			// ExtAudioFileSeek
			
			AudioBufferList bufList;
			bufList.mNumberBuffers 				= 1;
			bufList.mBuffers[0].mNumberChannels = audioFormat.mChannelsPerFrame;
			bufList.mBuffers[0].mData 			= audioData;
			bufList.mBuffers[0].mDataByteSize 	= numFrames * sizeof(AudioUnitSampleType);
			
			// perform a synchronous sequential read of the audio data out of the file into our allocated data buffer
			UInt32 numPackets = numFrames;
			status = ExtAudioFileRead(xafref, &numPackets, &bufList);
			if (status) {
				NSLog(@"(AudioFile.m) Failed to Read Data to AudioUnitSampleType for %@", fileName);
				free(audioData);
				audioData = 0;
				return nil;
			}
			
			// Close the file and dispse the URLRef
			ExtAudioFileDispose(xafref);
		}
	}
	
	return self;
}

#pragma mark --- Playback ---
- (void)play {
	if (!isPlaying) {
		
		AudioEngine *engine = [AudioEngine instance];
		
		AudioUnitSetParameter(engine.audioMixer,
							  kMultiChannelMixerParam_Enable,
							  kAudioUnitScope_Input,
							  busIndex,
							  YES,
							  0);
		
		isPlaying 	= YES;
		isPaused	= NO;
	}
}

- (void)pause {
	if(isPlaying) {
		AudioEngine *engine = [AudioEngine instance];
		
		AudioUnitSetParameter(engine.audioMixer,
							  kMultiChannelMixerParam_Enable,
							  kAudioUnitScope_Input,
							  busIndex,
							  NO,
							  0);
		
		sampleNum 	= 0;
		isPaused 	= YES;
		isPlaying	= NO;
	}
}

- (void)unpause {
	if(isPaused) {
		
		AudioEngine *engine = [AudioEngine instance];
		
		AudioUnitSetParameter(engine.audioMixer,
							  kMultiChannelMixerParam_Enable,
							  kAudioUnitScope_Input,
							  busIndex,
							  YES,
							  0);
		
		sampleNum 	= 0;
		isPaused 	= NO;
		isPlaying	= YES;
	}
}

- (void)stop {
	if (isPlaying) {
		
		AudioEngine *engine = [AudioEngine instance];
		
		AudioUnitSetParameter(engine.audioMixer,
							  kMultiChannelMixerParam_Enable,
							  kAudioUnitScope_Input,
							  busIndex,
							  NO,
							  0);
		
		sampleNum = 0;
		isPlaying = NO;
	}
}

#pragma mark --- Cleanup --
- (void)closeFile {
	if (isPlaying) {
		[self stop];
	}
	
	AudioEngine *engine = [AudioEngine instance];
	AUGraphDisconnectNodeInput(engine.audioGraph,
							   engine.mixerNode,
							   busIndex);
	
	open = NO;
	
	memset (&audioFormat, 0, sizeof (audioFormat));
	memset (audioData, 0, sizeof (audioFormat));
	free(audioData);
}

- (void)dealloc {
	[fileName release];
	// clear out audiobufferlist
	[super dealloc];
}

#pragma mark --- Property Methods ---
- (AudioUnitSampleType *)audioData { return audioData; }
- (void)setAudioData:(AudioUnitSampleType *)data {
	memcpy(audioData, data, sizeof(data));
}
@end
