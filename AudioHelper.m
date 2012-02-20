//
//  AudioHelper.m
//  CoreAudioTest
//
//  Created by Kevin Vitale on 1/20/10.
//  Copyright 2010 Vectorform, LLC. All rights reserved.
//

#import "AudioHelper.h"


@implementation AudioHelper

+ (NSString *)pathForResource:(NSString *)resource ofType:(NSString *)type {
	
	NSBundle *bundle = [NSBundle mainBundle];
	return [bundle pathForResource:resource ofType:type];
}

@end
