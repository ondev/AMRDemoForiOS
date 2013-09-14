//
//  MainViewController.m
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "wav.h"
#import "interf_dec.h"
#import "dec_if.h"
#import "interf_enc.h"
#import "amrFileCodec.h"

@implementation MainViewController


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareToRecord];
}

#define AMR_MAGIC_NUMBER "#!AMR\n"
const int sizes[] = { 12, 13, 15, 17, 19, 20, 26, 31, 5, 6, 5, 5, 0, 0, 0, 0 };
- (IBAction)amrnbToWavWay1:(id)sender
{
	
	NSString * path = [[NSBundle mainBundle] pathForResource:  @"test" ofType: @"amr"]; 
	
	FILE* in = fopen([path cStringUsingEncoding:NSASCIIStringEncoding], "rb");
	if (!in) 
	{
		NSLog(@"open file error");
	}
	
	char header[6];
	int n = fread(header, 1, 6, in);
	if (n != 6 || memcmp(header, "#!AMR\n", 6)) 
	{
		NSLog(@"Bad header");
	}
	
	WavWriter wav("out.wav", 8000, 16, 1);
	void* amr = Decoder_Interface_init();
	int frame = 0;
	
	
	unsigned char stdFrameHeader;
	
	while (true) {
		uint8_t buffer[500];
		/* Read the mode byte */
		
		unsigned char frameHeader;
		int size;
		int index;
		if (frame == 0) 
		{
			n = fread(&stdFrameHeader, 1, sizeof(unsigned char), in);
			index = (stdFrameHeader >> 3) &0x0f;
		}
		else
		{
			while(1)
			{
				n = fread(&frameHeader, 1, sizeof(unsigned char), in);
				if (feof(in)) return;
				if (frameHeader == stdFrameHeader) break;
			}
			index = (frameHeader >> 3) & 0x0f;
		}

		if (n <= 0)
			break;
		/* Find the packet size */
		size = sizes[index];
		if (size <= 0)
			break;
		n = fread(buffer + 1, 1, size, in);
		if (n != size)
			break;
		
		frame++;
		/* Decode the packet */
		int16_t outbuffer[160];
		Decoder_Interface_Decode(amr, buffer, outbuffer, 0);
		
		/* Convert to little endian and write to wav */
		uint8_t littleendian[320];
		uint8_t* ptr = littleendian;
		for (int i = 0; i < 160; i++) {
			*ptr++ = (outbuffer[i] >> 0) & 0xff;
			*ptr++ = (outbuffer[i] >> 8) & 0xff;
		}
		wav.writeData(littleendian, 320);
	}
	NSLog(@"frame=%d", frame);
	fclose(in);
	Decoder_Interface_exit(amr);
}

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)showInfo:(id)sender
{    
    FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
    controller.delegate = self;
    
    controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentModalViewController:controller animated:YES];
    
    [controller release];
}


- (void)prepareToRecord {
    // Set the audio file
    NSArray *pathComponents = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudioMemo.caf", nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    
    // Setup audio session
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    // Check Device Support Recording?
    BOOL supported = session.inputIsAvailable;
    if (! supported) {
        UIAlertView *cantRecordAlert = [[UIAlertView alloc] initWithTitle:@"Warning" message:@"Audio input hardware not available"
                                  delegate: nil  cancelButtonTitle:@"OK"  otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
    
    // Define the recorder setting
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:8000.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt:1] forKey:AVNumberOfChannelsKey];
    [recordSetting setObject:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    [recordSetting setObject:[NSNumber numberWithBool:NO] forKey: AVLinearPCMIsNonInterleaved];
    [recordSetting setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    [recordSetting setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    
    // Initiate and prepare the recorder
    recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
    recorder.delegate = self;
    recorder.meteringEnabled = YES;
    [recorder prepareToRecord];
}

- (IBAction)stopOrRecord:(id)sender {
    if (!recorder.recording) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        [session setActive:YES error:nil];
        
        // Start recording
        [recorder record];
        [sender setTitle:@"Stop" forState:UIControlStateNormal];
        
    } else {
        
        // Pause recording
        [recorder stop];
        [sender setTitle:@"Record" forState:UIControlStateNormal];
    }
}

- (IBAction)playRecord:(id)sender {
    NSArray *pathComponents = [NSArray arrayWithObjects:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"MyAudioMemo.caf", nil];
    NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
    NSString *cafPath = [outputFileURL path];
    NSString *amrPath = [NSHomeDirectory() stringByAppendingPathComponent: @"Documents/recording.amr"];
    EncodeCAFFileToAMRFile([cafPath cStringUsingEncoding:NSUTF8StringEncoding], [amrPath cStringUsingEncoding:NSUTF8StringEncoding]);
}

- (IBAction)amrnbToWavWay2:(id)sender
{
	DecodeAMRFileToWAVEFile("test.amr", "a.wav");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations.
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload
{
    [super viewDidUnload];

    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark
- (void) audioRecorderDidFinishRecording:(AVAudioRecorder *)avrecorder successfully:(BOOL)flag{
    NSString *cafPath = [[avrecorder url] path];
    NSString *amrPath = [NSHomeDirectory() stringByAppendingPathComponent: @"Documents/recording.amr"];
    EncodeCAFFileToAMRFile([cafPath cStringUsingEncoding:NSUTF8StringEncoding], [amrPath cStringUsingEncoding:NSUTF8StringEncoding]);
}

@end
