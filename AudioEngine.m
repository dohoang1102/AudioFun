//
//  AudioEngine.m
//  AudioUnitTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Vectorform, LLC. All rights reserved.
//

#import <AudioUnit/AudioUnit.h>
#import "AudioEngine.h"
#import "AudioFile.h"
#import "AudioHelper.h"


@implementation AudioEngine
@synthesize audioFilePaths;
@synthesize audioMixer;
@synthesize audioGraph;
@synthesize mixerNode,
			outputNode;
@synthesize totalNumBuses;
@synthesize audioFiles;
@synthesize busCounter;
@synthesize busToRemove;
@synthesize queue;

+ (AudioEngine *)instance {
	static AudioEngine *instance;
	@synchronized(instance) {
		if(instance == nil) {
			instance = [[AudioEngine alloc] init];
		}
	}
	
	return instance;
}

#pragma mark --- Initialize ---
- (id)init {
	if (self = [super init]) {
		
		audioFilePaths = [[NSMutableArray alloc] init];
		
		busToRemove = -1;
		currentAuxFile = 0;
		
		OSStatus status = noErr;
		
		// Create the audio graph
		status = NewAUGraph(&audioGraph);
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to create the AUGraph");
			return nil;
		}
		
		// Create the RemoteIO AU
		status = [self addOutputNodeToGraph];
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to add RemoteIO node to the AUGraph");
			return nil;
		}
		
		// Create the MultiChannel Mixer AU
		status = [self addMixerNodeToGraph];
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to add RemoteIO node to the AUGraph");
			return nil;
		}
		
		status = AUGraphConnectNodeInput(audioGraph, mixerNode, 0, outputNode, 0);
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to add Connect the Mixer with the Output Node within the AUGraph");
			return nil;
		}
		
		// Open the AUGraph
		status = AUGraphOpen(audioGraph);
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to open AUGraph");
			return nil;
		}
		
		// Add the AudioUnit Info
		status = AUGraphNodeInfo(audioGraph, mixerNode, NULL, &audioMixer);
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to add AudioUnit Info to the AUGraph");
			return nil;
		}
		
		// Set bus count
		status = [self setNumberOfAudioBuses:8];
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to set number of audio buses to %i", totalNumBuses);
			return nil;
		}
		
		/*
		// Create the MultiChannel Mixer AU
		status = [self setOutputToStereo];
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to set AudioUnit to Stereo");
			return nil;
		}
		*/
		
		status = AUGraphInitialize(audioGraph);
		if (status != noErr) {
			NSLog(@"(AudioEngine.m) Failed to initialize AUGraph");
			return nil;
		}
		
		NSOperationQueue *newQueue = [[NSOperationQueue alloc] init];
		[self setQueue:newQueue];
		[newQueue release];
	}
	
	
	
	NSLog(@"(AudioEngine.m) Audio Engine Successfully Created");
	return self;
}

- (void)dealloc {
	
	[audioFilePaths release];
	
	if (audioFiles) {
		[audioFiles release];
	}
	
	[queue release];
    [super dealloc];
}

#pragma mark --- Engine Functions
- (OSStatus)setNumberOfAudioBuses:(int)num {
	
	OSStatus status = noErr;
	
	UInt32 numBuses		= num - 1;
	self.totalNumBuses 	= numBuses;
	self.busCounter		= 0;
	
	NSLog(@"(AudioEngine.m) Setting Input Bus Count for %i files", numBuses);
	status = AudioUnitSetProperty(audioMixer,
								  kAudioUnitProperty_ElementCount,
								  kAudioUnitScope_Input,
								  0,
								  &numBuses,
								  sizeof(UInt32));
	
	if (status != noErr) {
		NSLog(@"(AudioEngine.m) Failed to set bus count");
		return status;
	}
	
	return status;
}
- (OSStatus)setOutputToStereo {
	OSStatus status = noErr;
	
	if(!audioMixer) {
		NSLog(@"(AudioEngine.m) AudioUnit for MixerNode is NULL");
		return -1;
	}
	
	UInt32 propSize = sizeof(AudioStreamBasicDescription);
	AudioStreamBasicDescription outputStreamDesc;
	status = AudioUnitGetProperty(audioMixer, 
								  kAudioUnitProperty_StreamFormat, 
								  kAudioUnitScope_Output, 
								  0, 
								  &outputStreamDesc, 
								  &propSize);
    
	if (status != noErr) {
		NSLog(@"(AudioEngine.m) Failed to get output unit's ASBD description");
		return status;
	}
	
	outputStreamDesc.mChannelsPerFrame 	= 1;
	outputStreamDesc.mSampleRate 		= 22050;
	outputStreamDesc.mFormatID			= kAudioFormatLinearPCM;
	outputStreamDesc.mFormatFlags 		= kAudioFormatFlagsCanonical;
	//outputStreamDesc.mBytesPerPacket 	= 2 * sizeof(AudioUnitSampleType);
	//outputStreamDesc.mBytesPerFrame 	= 2 * sizeof(AudioUnitSampleType);
	
	status = AudioUnitSetProperty(audioMixer,
								  kAudioUnitProperty_StreamFormat,
								  kAudioUnitScope_Input, 
								  0,
								  &outputStreamDesc,
								  sizeof(outputStreamDesc));
	
	if (status != noErr) {
		NSLog(@"(AudioEngine.m) Failed to set stereo output for audio mixer");
		return status;
	}
	
	return status;
}
- (OSStatus)addOutputNodeToGraph {
	OSStatus status = noErr;
	
	AudioComponentDescription au_description;
	au_description.componentType          = kAudioUnitType_Output;
	au_description.componentSubType       = kAudioUnitSubType_RemoteIO;
	au_description.componentManufacturer  = kAudioUnitManufacturer_Apple;
	au_description.componentFlags         = 0;
	au_description.componentFlagsMask     = 0;
	
	status = AUGraphAddNode(audioGraph, &au_description, &outputNode);
	return status;
}
- (OSStatus)addMixerNodeToGraph {
	OSStatus status = noErr;
	
	AudioComponentDescription au_description;
	au_description.componentType          = kAudioUnitType_Mixer;
	au_description.componentSubType       = kAudioUnitSubType_MultiChannelMixer;
	au_description.componentManufacturer  = kAudioUnitManufacturer_Apple;
	au_description.componentFlags         = 0;
	au_description.componentFlagsMask     = 0;
	
	status = AUGraphAddNode(audioGraph, &au_description, &mixerNode);
	return status;
}



#pragma mark --- Helper Functions
- (void)logActiveBuses {
	// Search for the audio file within the audio files array 
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"open == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate];
	
	NSLog(@"Active Bus Count: %i", [openAudioFiles count]);
}

#pragma mark --- Maintenance Function ---
- (BOOL)isRunning {
	Boolean isOpen;
	AUGraphIsRunning(audioGraph, &isOpen);
	
	return isOpen;
}

- (OSStatus)startEngine {
	if(self.audioFiles == nil)
		self.audioFiles = [NSMutableArray arrayWithCapacity:[self.audioFilePaths count]];
	
	BOOL running = [self isRunning];
	
	OSStatus status = noErr;
	if(running == NO) {
		status = AUGraphStart(audioGraph);
		if (status != noErr) {
			NSLog(@"(AudioUnitTestAppDelegate.m) Failed to START AUGraph");
			exit(1);
		}
	}
	
	return status;
}
- (OSStatus)stopEngine {
	if(self.audioFiles == nil)
		self.audioFiles = [NSMutableArray arrayWithCapacity:[self.audioFilePaths count]];
	
	BOOL running = [self isRunning];

	OSStatus status = noErr;
	if(running == YES) {
		
		for(AudioFile *audioFile in audioFiles) {
			[audioFile stop];
			[audioFile closeFile];
		}
		
		audioFiles = nil;
		
		status = AUGraphStop(audioGraph);
		if (status != noErr) {
			NSLog(@"(AudioUnitTestAppDelegate.m) Failed to STOP AUGraph");
			exit(1);
		}
	}
	
	return status;
}
- (void)restartAudioFiles {
	
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"isPlaying == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate]; 
	
	// Restart all the open audio files
	for(AudioFile *audioFile in openAudioFiles) {
		audioFile.sampleNum = 0;
	}
}

#pragma mark --- Audio File Functions ---
- (AudioFile *)audioFileForID:(int)audioID {
	
	if(audioFiles != nil) {
		
		// Search the array for an audio file containing the same index
		NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"audioIndex == %i", audioID];
		NSArray *resultsArray	= [audioFiles filteredArrayUsingPredicate:predicate];
		
		// Return the audio file with the same audioIndex
		if([resultsArray count] > 0) {
			return [resultsArray objectAtIndex:0];
		}
		
		
		// The audio file is not yet in the audio file array
		else {
			
			// Audio buses are still available
			if ([audioFiles count] < totalNumBuses) {
				// There are still buses that are available...
				
				NSString *audioFilePath = [AudioHelper pathForResource:[audioFilePaths objectAtIndex:audioID] ofType:@"aif"];
				AudioFile *audioFile = [[AudioFile alloc] initWithPath:audioFilePath andIndex:audioID];
				
				// Set the bus index at the array index it was just added to
				audioFile.busIndex = [audioFiles count];
				
				// Setup the callback
				AURenderCallbackStruct callbackStruct;
				callbackStruct.inputProc 		= PlaybackCallback;
				callbackStruct.inputProcRefCon	= audioFile;
				
				// Set the callback for the specified node's specified input
				OSStatus status = AUGraphSetNodeInputCallback(audioGraph,
															  mixerNode,
															  audioFile.busIndex,
															  &callbackStruct);
				if (status != noErr) {
					NSLog(@"(AudioEngine.m) Failed to create and establish the callback struct for %i audio file", index);
					return nil;
				}
				
				// Add it to the audio file array
				[audioFiles addObject:audioFile];
				[audioFile release];
				
				// Update the graph
				Boolean outOfDate = YES;
				AUGraphUpdate(audioGraph, &outOfDate);
				
				return [audioFiles lastObject];
			}
			
			// The bus index is full, so we need to replace an audio file alrady in the audio unit
			// 
			// Discussion:
			//	To determine the audio bus (and subsequently, the audio file) to be replaced, we need
			//	to understand the context we're adding the audio file.
			//
			//	For the purpose of the demo, each side of the demo screen has audio files whose
			//	audioIndex also serves as the bus index. The buttonTag of each button is set in IB
			//	then this buttonTag serves as the audioIndex identifier AND the bus index
			//
			//	For the Sprite game, there will be an array of strings; the index of these strings
			//	in the array will serve as the audioIndex for the newly created when a audiofile.
			//	The bux index, however, will be set based on where it is being added on the mixer.
			
			else {
				// Set the bus index to that of the file we're about to remove
				//
				//	Again...how we determine this will change based on the context of the application
				//	*  *  *
				//static int busToRemove = -1;		busToRemove++;
				//if(busToRemove == totalNumBuses)	busToRemove = 0;
				
				if(self.busToRemove > 0 && self.busToRemove <= totalNumBuses) {
					[[audioFiles objectAtIndex:busToRemove] closeFile];
					
					NSString *audioFilePath = [AudioHelper pathForResource:[audioFilePaths objectAtIndex:audioID] ofType:@"aif"];
					AudioFile *audioFile = [[AudioFile alloc] initWithPath:audioFilePath andIndex:audioID];
					
					audioFile.busIndex = busToRemove;
					
					// Setup the callback
					AURenderCallbackStruct callbackStruct;
					callbackStruct.inputProc 		= PlaybackCallback;
					callbackStruct.inputProcRefCon	= audioFile;
					
					// Set the callback for the specified node's specified input
					OSStatus status = AUGraphSetNodeInputCallback(audioGraph,
																  mixerNode,
																  audioFile.busIndex,
																  &callbackStruct);
					if (status != noErr) {
						NSLog(@"(AudioEngine.m) Failed to create and establish the callback struct for %i audio file", index);
						return nil;
					}
					
					[audioFiles replaceObjectAtIndex:busToRemove withObject:audioFile];
					[audioFile release];
					
					// Update the graph
					Boolean outOfDate = YES;
					AUGraphUpdate(audioGraph, &outOfDate);
					
					return [audioFiles objectAtIndex:busToRemove];
				}
				
				else {
					NSLog(@"(AudioEngine.m) Invalid busToRemove %i", busToRemove);
					return nil;
				}

			}
		}
	}
	
	return nil;
}

- (NSString *)fileNameForAudioID:(int)index {
	return [audioFilePaths objectAtIndex:index];
}

- (void)stopAllRunningAudioFiles {
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"isPlaying == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate]; 
	
	// Restart all the open audio files
	for(AudioFile *audioFile in openAudioFiles) {
		[audioFile stop];
		[audioFile closeFile];
	}
	
	[audioFile1 stop]; [audioFile1 closeFile];
	[audioFile2 stop]; [audioFile2 closeFile];
}


- (void)pauseAllPlayback {
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"isPlaying == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate]; 
	
	// Restart all the open audio files
	for(AudioFile *audioFile in openAudioFiles) {
		[audioFile pause];
	}
}

- (void)resumeAllPlayback {
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"isPaused == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate]; 
	
	// Restart all the open audio files
	for(AudioFile *audioFile in openAudioFiles) {
		[audioFile unpause];
	}
	
	[audioFile1 stop];
	[audioFile2 stop];
}

- (void)stopAuxiliaryAudioFile {
	[audioFile1 closeFile];
	[audioFile2 closeFile];
	
	audioFile1 = nil;
	audioFile2 = nil;
}

- (void)playAuxiliaryAudioFile:(NSString *)fileName {
	
	//NSLog(@"(AudioEngine.m) playAuxiliaryAudioFile: %@", fileName);
	
	NSString *audioFilePath = [AudioHelper pathForResource:fileName ofType:@"aif"];
	fileName = [fileName stringByAppendingPathExtension:@"aif"];

	if([fileName isEqualToString:audioFile1.fileName]) {
		[audioFile1 play];
		return;
	}
	
	/*
	if(audioFile1) {
		[audioFile1 play];
		return;
	}
	*/
	
	/*
	else if(audioFile2) {
		[audioFile1 play];
		return;
	}
	*/

	
	switch (currentAuxFile) {
		case 0: {
			if (audioFile1) {
				[audioFile1 closeFile];
				//[audioFile1 release];
				audioFile1 = nil;
			}
			
			audioFile1 = [[AudioFile alloc] initWithPath:audioFilePath andIndex:-1];
			
			audioFile1.busIndex = 7;
			
			// Setup the callback
			static AURenderCallbackStruct callbackStruct;
			callbackStruct.inputProc 		= PlaybackCallback;
			callbackStruct.inputProcRefCon	= audioFile1;
			
			// Set the callback for the specified node's specified input
			AUGraphSetNodeInputCallback(audioGraph,
										mixerNode,
										audioFile1.busIndex,
										&callbackStruct);
			
			// Update the graph
			Boolean outOfDate = YES;
			AUGraphUpdate(audioGraph, &outOfDate);
			
			[audioFile1 play];
			//currentAuxFile++;
			break;
		}
		
		default: 
			break;
	}
}

- (NSArray*)audioFileNames {
	
	NSMutableArray *namesArr = [NSMutableArray arrayWithCapacity:[audioFiles count]];
	
	NSPredicate *predicate	= [NSPredicate predicateWithFormat:@"isPlaying == YES"];
	NSArray *openAudioFiles = [audioFiles filteredArrayUsingPredicate:predicate]; 
	
	// Restart all the open audio files
	for(AudioFile *audioFile in openAudioFiles) {
		NSString *fileName = [audioFile fileName];
		[namesArr addObject:[fileName stringByDeletingPathExtension]];
	}
	
	return [NSArray arrayWithArray:namesArr];
}

#pragma mark --- Cleanup ---
+ (void)shutdown {
}

@end
