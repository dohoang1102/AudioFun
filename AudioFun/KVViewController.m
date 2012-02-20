//
//  KVViewController.m
//  AudioFun
//
//  Created by Kevin Vitale on 2/20/12.
//  Copyright (c) 2012 Barracuda Networks, Inc. All rights reserved.
//

#import "KVViewController.h"

@interface KVViewController ()

@end

@implementation KVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
