//
//  CGGView.m
//  CleanPests
//
//  Created by Eden on 16/7/26.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "CGGView.h"
#import "CGGPest.h"

@implementation CGGView

- (instancetype)init {
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSArray *subViews = self.subviews;
    for(UIView *subView in subViews){
        if([subView isKindOfClass:[CGGPest class]]){ //是要找的图片
            CALayer *layer = subView.layer.presentationLayer; //图片的显示层
            if(CGRectContainsPoint(layer.frame, point)){ //触摸点在显示层中，返回当前图片
                return subView;
            }
        }
    }
    return [super hitTest:point withEvent:event];
}

@end
