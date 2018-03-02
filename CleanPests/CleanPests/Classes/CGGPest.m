//
//  CGGPest.m
//  CleanPests
//
//  Created by Eden on 17/10/28.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "CGGPest.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface CGGPest()<CAAnimationDelegate> {
    AVAudioPlayer *_pestCrawlPlayer;
    SystemSoundID _pestTappedSoundID;
}

@property (nonatomic, strong) UIImageView *pestImgView;
@property (nonatomic, assign) CGPoint destinationPoint;
@property (nonatomic, copy) CGGPestMoveCompletion completion;

@property (nonatomic, assign) BOOL showing;

@end

@implementation CGGPest

#pragma mark -------------------- init --------------------

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0, 0, 70, 88)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:CGRectMake(0, 0, 70, 88)]) {
        self.speed = 200;
        self.playCrawlSound = YES;
        self.playTappedSound = YES;
        self.showing = NO;
        [self setupView];
        [self loadPestImage];
    }
    return self;
}

+ (instancetype)pestSpeed:(NSInteger)speed {
    
    CGGPest *pest = [CGGPest new];
    if (speed > 0) {
        pest.speed = speed;
    }
    
    return pest;
}

- (void)setupView {
    
    self.pestImgView = [[UIImageView alloc] initWithFrame:self.bounds];
    [self addSubview:self.pestImgView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(pestImgViewTapped:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)loadPestImage {
    
    NSMutableArray *zhanglangs = [NSMutableArray array];
    for (NSInteger i = 1 ; i <= 12 ; i++) {
        NSString *name = [NSString stringWithFormat:@"zhanglang%lu.tiff",(long)i];
        UIImage *image = [UIImage imageNamed:name];
        [zhanglangs addObject:image];
    }
    
    self.pestImgView.animationImages = zhanglangs;
    [self.pestImgView startAnimating];
}

#pragma mark -------------------- Override --------------------

- (void)removeFromSuperview {
    self.showing = NO;
    [super removeFromSuperview];
}

#pragma mark -------------------- Public --------------------

- (void)showInView:(UIView*)view {
    self.showing = YES;
    [view addSubview:self];
}

- (void)putAtPoint:(CGPoint)aPoint {
    //此处不能用修改frame，否则会导致frame错乱
    self.center = CGPointMake(aPoint.x+50, aPoint.y+50);
}

- (void)moveToPoint:(CGPoint)aPoint completion:(CGGPestMoveCompletion)completion {
    
    if (self.playCrawlSound) {
        [self playPestCrawlAudio];
    }
    
    self.destinationPoint = aPoint;
    self.completion = completion;
    
    //由于蟑螂本身是朝上的所以要顺时针旋转90度°
    self.transform = CGAffineTransformMakeRotation(M_PI_2 - [self p_calculatePestRotationAngle]);
    
    CGFloat destance = [self p_distanceFromPoint:self.frame.origin
                                       toPoint:aPoint];
    NSTimeInterval duration = destance/self.speed;
    
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    animation.duration = duration;
    animation.delegate = self;
    animation.fromValue = [NSValue valueWithCGPoint:self.frame.origin];
    animation.toValue = [NSValue valueWithCGPoint:aPoint];
    
    [self.layer addAnimation:animation forKey:@"PestCrawling"];
}

- (void)pause {
    CFTimeInterval pausedTime = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil];
    self.layer.speed = 0.0;
    self.layer.timeOffset = pausedTime;
}

- (void)resume {
    
    CFTimeInterval pausedTime = [self.layer timeOffset];
    self.layer.speed = 1.0;
    self.layer.timeOffset = 0.0;
    self.layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [self.layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    self.layer.beginTime = timeSincePause;
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {

    //消失动画
    if ([anim isKindOfClass:[CAAnimationGroup class]]) {
        [self.layer removeAnimationForKey:@"PestCrawling"];
        NSLog(@"Pest:%@ dismiss animation was finished",self);
        return;
    }

    if (self.playCrawlSound) {
        [self stopPestCrawlAudio];
    }

    if (!flag) {
        [self removeFromSuperview];
        NSLog(@"Pest:%@ was removed from superview",self);
    }
    
    if (self.completion) {
        self.completion(flag);
    }
}

#pragma mark -------------------- Tap Action --------------------

- (void)pestImgViewTapped:(UITapGestureRecognizer*)gesture {
    
    if (self.playTappedSound) {
        [self playPestTappedAudio];
    }
    
    //缩放动画
    CABasicAnimation *scaleAnima = [CABasicAnimation animationWithKeyPath:@"transform.scale"];//同上
    scaleAnima.toValue = [NSNumber numberWithFloat:3.0f];

    //消失动画
    CABasicAnimation *opacityAnima = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnima.fromValue = [NSNumber numberWithFloat:1.0f];
    opacityAnima.toValue = [NSNumber numberWithFloat:0];

    //组合动画
    CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
    groupAnimation.animations = @[scaleAnima,opacityAnima];
    groupAnimation.duration = 0.25f;
    groupAnimation.delegate = self;
    
    [self.layer addAnimation:groupAnimation forKey:@"PestDismissing"];
}

#pragma mark -------------------- Audio --------------------

- (void)playPestCrawlAudio {
    if (_pestCrawlPlayer == nil) {
        NSString *musicFilePath = [[NSBundle mainBundle] pathForResource:@"pest_crawl" ofType:@"mp3"];
        NSURL *musicURL = [[NSURL alloc] initFileURLWithPath:musicFilePath];
        
        AVAudioPlayer *thePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:nil];
        [thePlayer prepareToPlay];
        [thePlayer setVolume:0.3];
        thePlayer.numberOfLoops = -1;//设置音乐播放次数  -1为一直循环
        _pestCrawlPlayer = thePlayer;
    }
    [_pestCrawlPlayer play];
}

- (void)stopPestCrawlAudio {
    [_pestCrawlPlayer stop];
}

- (void)playPestTappedAudio {
    
    if (_pestTappedSoundID == 0) {
        NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"pest_tapped"
                                                                  ofType:@"aif"];
        NSURL *urlPath = [NSURL fileURLWithPath:audioFilePath isDirectory:NO];
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)urlPath, &_pestTappedSoundID);
    }
    AudioServicesPlaySystemSound(_pestTappedSoundID);
}

#pragma mark -------------------- Private --------------------

- (CGFloat)p_calculatePestRotationAngle {
    
    CGFloat xOffset = (_destinationPoint.x - self.frame.origin.x);
    CGFloat yOffset = -(_destinationPoint.y - self.frame.origin.y);
    
    CGFloat angle = atanf((yOffset/xOffset));
    
    if (xOffset > 0 && yOffset > 0) {
        //第一象限
    } else if (xOffset < 0 && yOffset > 0) {
        //第二象限
        angle = M_PI + angle;
    } else if (xOffset < 0 && yOffset < 0) {
        //第三象限 x f g t'
        angle += M_PI;
    } else if (xOffset > 0 && yOffset < 0) {
        //第四象限
        angle = 2*M_PI + angle;
    }
    
    return angle;
}

- (CGFloat)p_distanceFromPoint:(CGPoint)fromPoint toPoint:(CGPoint)toPoint {
    return hypot((toPoint.x - fromPoint.x),(toPoint.y - fromPoint.y));
}

@end
