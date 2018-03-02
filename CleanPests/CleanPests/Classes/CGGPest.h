//
//  CGGPest.h
//  CleanPests
//
//  Created by Eden on 17/10/28.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^CGGPestMoveCompletion)(BOOL finished);

@interface CGGPest : UIView

//100为单位，默认值300，小于0时改为默认值
@property (nonatomic, assign) NSInteger speed;

@property (nonatomic, assign) BOOL playCrawlSound;//爬行时是否播放声音，默认YES
@property (nonatomic, assign) BOOL playTappedSound;//点击时是否播放声音，默认YES
//是否可见，默认为NO，调用showInView:方法后设为YES,调用removefromSuperview后设为NO
@property (nonatomic, readonly, getter=isShowing) BOOL showing;

+ (instancetype)pestSpeed:(NSInteger)speed;

- (void)showInView:(UIView*)view;

- (void)putAtPoint:(CGPoint)aPoint;
- (void)moveToPoint:(CGPoint)aPoint completion:(CGGPestMoveCompletion)completion;

- (void)pause;
- (void)resume;

@end
