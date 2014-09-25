//
//  ELGraphView.h
//  TimedCamera
//
//  Created by 王羽丰 on 14-9-22.
//  Copyright (c) 2014年 ericksonlab. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ELGraphView : UIView {
    NSArray *internalData;
    int interanlHeight;
}

@property (nonatomic, assign) UInt64 some;


- (void)updateInternalData:(NSArray*)accLig;
- (void)setInternalHeight:(int) height;

@end
