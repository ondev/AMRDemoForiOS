//
//  MainViewController.h
//  amrDemoForiOS
//
//  Created by Tang Xiaoping on 9/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate, AVAudioRecorderDelegate> {
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
}

- (void)prepareToRecord;

- (IBAction)showInfo:(id)sender;
- (IBAction)amrnbToWavWay1:(id)sender;
- (IBAction)amrnbToWavWay2:(id)sender;
- (IBAction)stopOrRecord:(id)sender;
- (IBAction)playRecord:(id)sender;

@end
