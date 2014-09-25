//
//  ELGraphView.m
//  TimedCamera
//
//  Created by 王羽丰 on 14-9-22.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import "ELGraphView.h"

@implementation ELGraphView

@synthesize some;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        interanlHeight = 0;
        internalData = [[NSArray alloc] init];
    }
    return self;
}

- (void)updateInternalData:(NSArray*)accLig{
    internalData = accLig;
}

- (void)setInternalHeight:(int)height {
    interanlHeight = height;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // What rectangle am I filling?
    CGRect bounds = [self bounds];
    // Where is its center?
    CGPoint center;
    center.x = bounds.origin.x + bounds.size.width / 2.0;
    center.y = bounds.origin.y + bounds.size.height / 2.0;
    // From the center how far out to a corner?
    //float maxRadius = hypot(bounds.size.width, bounds.size.height) / 2.0;
    // Get the context being drawn upon
    CGContextRef context = UIGraphicsGetCurrentContext();
    // All lines will be drawn 10 points wide
    CGContextSetLineWidth(context, 5);
    // Set the stroke color
    [[UIColor blackColor] setStroke];
    // Draw coordinary axis
    CGContextMoveToPoint(context, 0, 200);
    CGContextAddLineToPoint(context,300,200);
    CGContextMoveToPoint(context, 0, 0);
    CGContextAddLineToPoint(context,0,200);
    CGContextStrokePath(context);
    // Draw curve
    CGContextSetLineWidth(context, 3);
    [[UIColor redColor] setStroke];
    for (int i=1; i<interanlHeight; i++) {
        float x1=300.0*(i-1)/interanlHeight;
        float x2=300.0*i/interanlHeight;
        NSNumber* number = [internalData objectAtIndex:(i-1)];
        float y1 = 200.0*number.floatValue;
        number = [internalData objectAtIndex:(i)];
        float y2 = 200.0*number.floatValue;
        CGContextMoveToPoint(context, x1, y1);
        CGContextAddLineToPoint(context, x2, y2);
    }
    CGContextStrokePath(context);
}



@end
