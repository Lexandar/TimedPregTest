//
//  ELcholAnalyzer.m
//  TimedCamera
//
//  Created by 王羽丰 on 14-7-10.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import "ELCholAnalyzer.h"
#import <math.h>


@implementation ELCholAnalyzer

@synthesize cameraType, session, draggablePreview, visiblePreview, stillImageOutput, videoConnection,videoDataOutput,hasImageData,torchOn,captureDevice;

typedef struct {
    int hue;
    float sat,lig;
    BOOL valid;
}HSLpixel;

int maxValue(int r, int g, int b){
    int max = r;
    if (g>max) max = g;
    if (b>max) max = b;
    return max;
}

int minValue(int r, int g, int b){
    int min = r;
    if (g<min) min = g;
    if (b<min) min = b;
    return min;
}

int hueFromRGB(int r, int g, int b){
    int max = maxValue(r, g, b);
    int min = minValue(r, g, b);
    float dif = max - min;
    if (dif==0) return 0;
    else if (max == r && g>=b) return (int)roundf(60*(g-b)/dif);
    else if (max == r && g<b) return (int)roundf(60*(g-b)/dif+360);
    else if (max == g) return (int)roundf(60*(b-r)/dif+120);
    else return (int)roundf(60*(r-g)/dif+240);
}

float satFromRGB(int r, int g, int b){
    float l = ligFromRGB(r,g,b);
    float max = maxValue(r, g, b);
    float min = minValue(r, g, b);
    float dif = (float)(max - min)/2.55;
    if (l<0.5) return dif/l/2;
    else return dif/(2-2*l);
}

float ligFromRGB(int r, int g, int b){
    return 0.5*(maxValue(r, g, b) + minValue(r, g, b))/255;
}


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setDefaults];
    }
    return self;
}

- (id)initWithDeviceType:(DeviceType)type
      inTotalTime:(NSInteger)totalTime
      withInterval:(NSInteger)timeInterval
{
    CGRect previewFrame;
    //Set preview visiblity here
    self.visiblePreview = YES;
    switch (type)
    {
        case 0:
            previewFrame = CGRectMake(180, 30, 120, 90);
            break;
        case 1:
            previewFrame = CGRectMake(180, 30, 30, 120);
            break;
        case 2:
            previewFrame = CGRectMake(30, 30, 90, 70);
            break;
        default:
            previewFrame = CGRectMake(30, 30, 90, 70);
            break;
    }
    if (!visiblePreview) {
        previewFrame = CGRectMake(0, 0, 0, 0);
    }
    self = [super initWithFrame:previewFrame];
    if (self) {
        [self setDefaults];
    }
    self.totalTime = totalTime;
    if (timeInterval<1) {
        NSLog(@"Time interval too short, set to 1s");
        timeInterval = 1;
    }
    self.timeInterval = timeInterval;
    NSUInteger num = totalTime / timeInterval;
    self.sampleImageBuffer = [NSMutableArray arrayWithCapacity:num];
    return self;
    
}

- (void)setDefaults
{
    [self setBackgroundColor:[UIColor blackColor]];
    self.layer.cornerRadius = 5;
    self.layer.masksToBounds = YES;
    self.cameraType = AVCaptureDevicePositionBack;
    self.draggablePreview = YES;
    self.hasImageData = NO;
    self.torchOn = YES;
    self.videoStopped = YES;
    }ßß

- (void)startCam
{
    AVCaptureDevice *device = [self CameraIfAvailable];
    
    if (device) {
        if (!session) {
            session = [[AVCaptureSession alloc] init];
        }
        session.sessionPreset = AVCaptureSessionPresetLow;
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        if (!input){
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR:" message:@"Cannot open camera"  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
            [alert show];
            NSLog(@"ERROR: trying to open camera:%@", error);
        } else {
            if ([session canAddInput:input]) {
                //Everythings working, start running camera
                [session addInput:input];
                if (self.visiblePreview) {
                    //Show preview of graph
                    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
                    
                    captureVideoPreviewLayer.frame = self.bounds;
                    captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                    
                    [self.layer addSublayer:captureVideoPreviewLayer];
                }
                [session startRunning];
                self.videoStopped = NO;
                //Set up image output;
                //StillImageOutput code
                /*if (captureDevice.torchMode == AVCaptureTorchModeOn)
                    NSLog(@"Torch on");
                else NSLog(@"Torch off");
                stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
                NSDictionary *imageOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey ,nil];
                [stillImageOutput setOutputSettings:imageOutputSettings];
                [session addOutput:stillImageOutput];
                */
                
                //videoDataOutput code
                videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
                videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey: (id)kCVPixelBufferPixelFormatTypeKey];
                
                [videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
                dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
                [videoDataOutput setSampleBufferDelegate:self queue:queue];
                dispatch_release(queue);
                
                
                AVCaptureConnection *connection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
                [connection setVideoMaxFrameDuration:CMTimeMake(1, 20)];
                [connection setVideoMinFrameDuration:CMTimeMake(1, 10)];
                
                [[self session] addOutput:videoDataOutput];
                //Turn on flash light
                if ([captureDevice hasTorch] && [captureDevice hasFlash] && self.torchOn) {
                    if (captureDevice.torchMode == AVCaptureTorchModeOff)  {
                        [session beginConfiguration];
                        [captureDevice lockForConfiguration:nil];
                        [captureDevice setTorchMode:AVCaptureTorchModeOn];
                        [captureDevice setFlashMode:AVCaptureFlashModeOn];
                        [captureDevice unlockForConfiguration];
                        [session commitConfiguration];
                    }
                }
                
                self.timeStart = [[NSDate date] timeIntervalSince1970]*1000;
                self.timeLastImageCaptured = self.timeStart;
                
                
                //Find correct AVCaputureConnection in AVCaptureStillImageOutput
                //StillImageOutput code
                /*
                for (AVCaptureConnection *connection in stillImageOutput.connections) {
                    for (AVCaptureInputPort *port in [connection inputPorts]) {
                        if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                            videoConnection = connection;
                            break;
                        }
                    }
                }*/

            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR:" message:@"Couldn't add input"  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
                [alert show];
                NSLog(@"ERROR: Couldn't add input");
            }
        }
        
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"ERROR:" message:@"Camera not available"  delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
        NSLog(@"ERROR: Camera not available");
    }
                               
}

- (AVCaptureDevice *)CameraIfAvailable
{
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
//    AVCaptureDevice *captureDevice = nil;
    for (AVCaptureDevice *device in videoDevices)
    {
        if (device.position == self.cameraType) {
            captureDevice = device;
            break;
        }
    }
    
    //If no capture device found
    if (!captureDevice) {
        captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    }
    
    return captureDevice;
}

-(void) captureOutput:(AVCaptureOutput *)captureOutput
        didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    UInt64 timeNow = [[NSDate date] timeIntervalSince1970] * 1000;
    if (timeNow - self.timeLastImageCaptured >= self.timeInterval * 1000) {
        UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
        if (image) {
            NSLog(@"Image snapped:%f * %f",image.size.width,image.size.height);
        } else {
            NSLog(@"Image snapped, but null");
        }
        
        self.timeLastImageCaptured = self.timeLastImageCaptured + self.timeInterval * 1000;
        self.imageData = UIImageJPEGRepresentation(image, 1.0);
        [self.sampleImageBuffer addObject:self.imageData];
    }
    
    if (timeNow - self.timeStart > self.totalTime * 1000) {
        NSLog(@"timeNow:%lld  timeStart:%lld  timeTotal:%lld",timeNow,self.timeStart,self.totalTime);
        [self stopVideoCapture];
    }
    
}

- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    dataVol = width;
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    if (!colorSpace)
    {
        NSLog(@"CGColorSpaceCreateDeviceRGB failure");
        return nil;
    }
    // Get the base address of the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    UInt8 *pointer = (UInt8 *)baseAddress;
    // Get the data size for contiguous planes of the pixel buffer.
    size_t bufferSize = CVPixelBufferGetDataSize(imageBuffer);
    // Creat a array with hsv color data
    int size = (int)(bufferSize - 8)/4; //Each 4 bytes represents a pixel, except last 8 bytes
    HSLpixel pixels[size];
    float pixelCount[1000] = {0};
    for (int i = 0; i<size; i++) {
        int b = *pointer; pointer++;
        int g = *pointer; pointer++;
        int r = *pointer; pointer=pointer+2; //Skip alpha value
        pixels[i].hue = hueFromRGB(r,g,b);
        pixels[i].lig = ligFromRGB(r,g,b);
        pixels[i].sat = satFromRGB(r,g,b);
        if((float)(i / width)>0.25*height && (float)(i / width)<0.75*height)
            pixelCount[i % width] = pixelCount[i % width] + (float)ligFromRGB(r, g, b) *2 / width;
    }
    accLig = [[NSMutableArray alloc] init];
    for (int i = 0; i<width; i++) {
        NSNumber *number = [NSNumber numberWithFloat:pixelCount[i]];
        [accLig addObject:number];
    }
    
    // Create a Quartz direct-access data provider that uses data we supply
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, baseAddress, bufferSize, NULL);
    // Create a bitmap image from data supplied by our data provider
    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, bytesPerRow, colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, provider, NULL, true, kCGRenderingIntentDefault);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    // Create and return an image object representing the specified Quartz image
    UIImage *image = [UIImage imageWithCGImage:cgImage scale:1 orientation:UIImageOrientationRight];
    CGImageRelease(cgImage);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return image;
}

- (NSData *) snapCurrentImage
{
    //StillImageOutput code
    /*void (^myHandler)(CMSampleBufferRef imageDataSampleBuffer, NSError *error) = ^(CMSampleBufferRef imageDataSampleBuffer, NSError *error){
        NSLog(@"Block start");
        //完成撷取时的处理程序(Block)
        if (imageDataSampleBuffer) {
            self.imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            
            //取得影像数据（需要ImageIO.framework 与 CoreMedia.framework）
            CFDictionaryRef myAttachments = CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyExifDictionary, NULL);
            NSLog(@"影像属性: %@", myAttachments);
            self.hasImageData = YES;
        }
    };
    [stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:myHandler];*/
    
         //Snap image
    return (self.imageData);
}

- (NSData *) showCurrentImage
{
    int i = 0;
    while (!self.hasImageData && i<10) {
        [NSThread sleepForTimeInterval:0.1];
        i++;
    }
    if (i==10)
        return (NULL);
    self.hasImageData = NO;
    return self.imageData;
}

- (void)stopVideoCapture
{
    
    //Stop camera session
    
    if(session){
        
        if (captureDevice.torchMode == AVCaptureTorchModeOn)  {
            [session beginConfiguration];
            [captureDevice lockForConfiguration:nil];
            [captureDevice setTorchMode:AVCaptureTorchModeOff];
            [captureDevice setFlashMode:AVCaptureFlashModeOff];
            [captureDevice unlockForConfiguration];
            [session commitConfiguration];
        }
        
        [session stopRunning];
        
        session= nil;
        self.videoStopped = YES;
        NSLog(@"Video capture stopped");
        
    }
}

- (NSArray *) getAccLig {
    NSArray * tempArr = [[NSArray alloc] initWithArray:accLig];
    return tempArr;    
}

- (int) getDataVol {
    return dataVol;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *aTouch = [touches anyObject];
    offset = [aTouch locationInView: self];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (self.visiblePreview && self.draggablePreview) {
        UITouch *touch = [touches anyObject];
        CGPoint location = [touch locationInView:self.superview];
        [UIView beginAnimations:@"Dragging" context:nil];
        self.frame = CGRectMake(location.x-offset.x, location.y-offset.y, self.frame.size.width, self.frame.size.height);
        [UIView commitAnimations];
    }
}

@end
