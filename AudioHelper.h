//
//  AudioHelper.h
//  CoreAudioTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Vectorform, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kOutputBus 	0
#define kInputBus	1

@interface AudioHelper : NSObject {

}

+ (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type;

@end
