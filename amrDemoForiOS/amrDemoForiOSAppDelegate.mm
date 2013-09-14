//
//  amrDemoForiOSAppDelegate.m
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "amrDemoForiOSAppDelegate.h"

#import "MainViewController.h"
#import "wav.h"
#import "interf_dec.h"
#import "dec_if.h"
#import "interf_enc.h"
#import "amrFileCodec.h"

@implementation amrDemoForiOSAppDelegate


@synthesize window=_window;

@synthesize mainViewController=_mainViewController;

/* From WmfDecBytesPerFrame in dec_input_format_tab.cpp */


/* From pvamrwbdecoder_api.h, by dividing by 8 and rounding up */
const int sizes1[] = { 17, 23, 32, 36, 40, 46, 50, 58, 60, 5, -1, -1, -1, -1, -1, -1 };
- (void)amrwbToWav
{
	NSString * path = [[NSBundle mainBundle] pathForResource:  @"test" ofType: @"amr"];
	FILE* in = fopen([path cStringUsingEncoding:NSASCIIStringEncoding], "rb");
	if (!in) {
		NSLog(@"open file error");
		return;
	}
	char header[9];
	int n = fread(header, 1, 9, in);
	if (n != 9 || memcmp(header, "#!AMR-WB\n", 9)) 
	{
		NSLog(@"Bad header");
		return;
	}
	
	WavWriter wav("out.wav", 16000, 16, 1);
	void* amr = D_IF_init();
	while (true) {
		uint8_t buffer[500];
		/* Read the mode byte */
		n = fread(buffer, 1, 1, in);
		if (n <= 0)
			break;
		/* Find the packet size */
		int size = sizes1[(buffer[0] >> 3) & 0x0f];
		if (size <= 0)
			break;
		n = fread(buffer + 1, 1, size, in);
		if (n != size)
			break;
		
		/* Decode the packet */
		int16_t outbuffer[320];
		D_IF_decode(amr, buffer, outbuffer, 0);
		
		/* Convert to little endian and write to wav */
		uint8_t littleendian[640];
		uint8_t* ptr = littleendian;
		for (int i = 0; i < 320; i++) {
			*ptr++ = (outbuffer[i] >> 0) & 0xff;
			*ptr++ = (outbuffer[i] >> 8) & 0xff;
		}
		wav.writeData(littleendian, 640);
	}
	fclose(in);
	D_IF_exit(amr);
}

- (void)wavToamrnb
{
	
	NSArray *paths               = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath       = [paths objectAtIndex:0];
	NSString *outFilePath        = [documentPath stringByAppendingPathComponent:@"out.amr"];
    NSString * inFilePath = [[NSBundle mainBundle] pathForResource:  @"beep" ofType: @"wav"];
	EncodeWAVEFileToAMRFile([inFilePath cStringUsingEncoding:NSUTF8StringEncoding], [outFilePath cStringUsingEncoding:NSUTF8StringEncoding], 1, 16);
                            
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	// Override point for customization after application launch.
	// Add the main view controller's view to the window and display.
	self.window.rootViewController = self.mainViewController;
	[self.window makeKeyAndVisible];
//	[self amrnbToWav];
	[self wavToamrnb];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	/*
	 Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	 Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	 */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	/*
	 Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
	 If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	 */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	/*
	 Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	 */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	/*
	 Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	 */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	/*
	 Called when the application is about to terminate.
	 Save data if appropriate.
	 See also applicationDidEnterBackground:.
	 */
}

- (void)dealloc
{
	[_window release];
	[_mainViewController release];
    [super dealloc];
}

@end
