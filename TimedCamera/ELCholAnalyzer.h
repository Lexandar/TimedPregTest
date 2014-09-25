//
//  ELcholAnalyzer.h
//  TimedCamera
//
//  Created by 王羽丰 on 14-7-10.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import <CoreVideo/CoreVideo.h>

typedef enum{
    IPHONE3x5 = 0,
    IPHONE4 = 1,
    IPAD = 2,
} DeviceType;


@interface ELCholAnalyzer : UIView <AVCaptureVideoDataOutputSampleBufferDelegate>{
    CGPoint offset;
    NSMutableArray *accLig;
    int dataVol;
}


@property (nonatomic, assign) AVCaptureDevicePosition cameraType;
@property (nonatomic, assign) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureSession *session;
@property (strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) UITableView *satTable;
@property (nonatomic, assign) BOOL draggablePreview;
@property (nonatomic, assign) BOOL visiblePreview;
@property (nonatomic, assign) BOOL hasImageData;
@property (nonatomic, assign) BOOL torchOn;
@property (nonatomic, assign) BOOL videoStopped;
@property (nonatomic, assign) UInt64 timeLastImageCaptured;
@property (nonatomic, assign) UInt64 timeStart;
@property (nonatomic, assign) UInt64 totalTime;
@property (nonatomic, assign) UInt64 timeInterval;

//@property (nonatomic, assign) NSDate *currentDate;


@property (strong) NSData *imageData;
@property (strong) UIImage *image;
@property (strong) NSMutableArray *sampleImageBuffer;


-(id) initWithDeviceType : (DeviceType)type
      inTotalTime : (NSInteger) totalTime
      withInterval: (NSInteger) timeInterval;
-(void) startCam;
-(void) setDefaults;
-(NSData *) snapCurrentImage;
-(NSData *) showCurrentImage;
-(AVCaptureDevice *) CameraIfAvailable;
-(void) stopVideoCapture;
-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection;
-(NSArray *) getAccLig;
- (int) getDataVol;

@end
