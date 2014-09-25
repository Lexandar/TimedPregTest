//
//  ELViewController.h
//  TimedCamera
//
//  Created by 王羽丰 on 14-7-10.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCholAnalyzer.h"
#import "ELGraphView.h"

@interface ELViewController : UIViewController

- (IBAction)startTest:(UIButton *)sender;
- (IBAction)showImage:(UIButton *)sender;
@property (nonatomic, assign) BOOL cameraOn;
@property (nonatomic, strong) NSDate *startDate;
@property (nonatomic, assign) int totalCount;
@property (nonatomic, assign) int count;
@property (strong, nonatomic) ELCholAnalyzer *cholAnalyzer;
@property (strong, nonatomic) ELGraphView *graphView;
@property (weak, nonatomic) IBOutlet UIImageView *snappedImage;
@property (weak, nonatomic) IBOutlet UITextField *testLength;
@property (weak, nonatomic) IBOutlet UITextField *sampleInterval;

- (IBAction)lengthEndEditing:(id)sender;
- (IBAction)intervalEndEditing:(id)sender;


-(void) updateLabel;

@end
