//
//  ELViewController.m
//  TimedCamera
//
//  Created by 王羽丰 on 14-7-10.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import "ELViewController.h"


@interface ELViewController ()

@end

@implementation ELViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.cameraOn = NO;
    CGRect rect = CGRectMake(10, 250, 300, 200);
    self.graphView = [[ELGraphView alloc] initWithFrame:rect];
    [self.graphView setBackgroundColor:[UIColor colorWithRed:20 green:20 blue:0 alpha:0.1]];
    [self.view addSubview:self.graphView];
  //  [self.graphView drawRect:rect];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)lengthEndEditing:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)intervalEndEditing:(id)sender {
    [sender resignFirstResponder];
}

- (void)updateLabel {
    
    if (self.count <= self.totalCount){
    UIImage *image = [UIImage imageWithData:self.cholAnalyzer.imageData];
    if (image)
    {
        self.count++;
        UIImageWriteToSavedPhotosAlbum(image,nil,nil,nil) ;
        self.cholAnalyzer.imageData = nil;
        [self.graphView updateInternalData:[self.cholAnalyzer getAccLig]];
        [self.graphView setInternalHeight:[self.cholAnalyzer getDataVol]];
        [self.graphView setNeedsDisplay];
    }
    }
}

- (void)viewDidUnload {
    [self setSnappedImage:nil];
    [self setTestLength:nil];
    [self setSampleInterval:nil];
    [super viewDidUnload];
}
- (IBAction)startTest:(UIButton *)sender {
    NSString *testLength = _testLength.text;
    NSString *sampleInterval = _sampleInterval.text;
    int totalTime = [testLength intValue];
    int interval = [sampleInterval intValue];
    self.startDate = [[NSDate alloc] initWithTimeIntervalSinceNow:(float)interval/2.0];
    self.totalCount = totalTime / interval + 1;
    self.count = 0;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:(float)interval / 1.0 target:self selector:@selector(updateLabel) userInfo:nil repeats:YES];
//    [timer setFireDate:self.startDate];
    [timer fire];
    if (!self.cholAnalyzer) {
        self.cholAnalyzer = [[ELCholAnalyzer alloc] initWithDeviceType:IPHONE3x5 inTotalTime:totalTime withInterval:interval];
        [self.cholAnalyzer startCam];
        [self.view addSubview:self.cholAnalyzer];
        self.cameraOn = YES;
        
    } else if (self.cholAnalyzer.videoStopped){
        [self.cholAnalyzer removeFromSuperview];
        self.cholAnalyzer = nil;
        [timer invalidate];
        timer = nil;
    }
    
}

- (IBAction)showImage:(UIButton *)sender {
    if (self.cholAnalyzer) {
        if (self.cholAnalyzer.image)
            NSLog(@"Have image");
        UIImage *currentImage = [UIImage imageWithData:self.cholAnalyzer.imageData];
        _snappedImage.image = currentImage;
    }
}
@end
