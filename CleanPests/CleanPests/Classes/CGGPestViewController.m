//
//  CGGPestViewController.m
//  CleanPests
//
//  Created by Eden on 16/7/25.
//  Copyright © 2017年 Eden. All rights reserved.
//

#import "CGGPestViewController.h"
#import "CGGPest.h"
#import <AVFoundation/AVFoundation.h>


#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

struct CGGNumberRange {
    NSInteger min;
    NSInteger max;
};

typedef struct CGGNumberRange CGGNumberRange;

CGGNumberRange CGGNumberRangeMake(NSInteger min, NSInteger max) {
    CGGNumberRange range; range.min = min; range.max = max ; return range;
}

static CGGNumberRange _leftXRange;//左边x的范围
static CGGNumberRange _rightXRange;//右边x的范围
static CGGNumberRange _topYRange;//上边y的范围
static CGGNumberRange _bottomYRange;//下边y的范围

static const int _pestAmounts = 10;//害虫数量

@interface CGGPestViewController () {
    NSMutableArray *_pests;
    AVAudioPlayer *_bgmPlayer;
}

@end

@implementation CGGPestViewController

#pragma mark -------------------- Life Cycle --------------------

+ (void)initialize {
    [super initialize];
    
    _leftXRange = CGGNumberRangeMake(-200, -100);
    _rightXRange = CGGNumberRangeMake(kScreenWidth, kScreenWidth+100);
    
    _topYRange = CGGNumberRangeMake(-200, -100);
    _bottomYRange = CGGNumberRangeMake(kScreenHeight, kScreenHeight+100);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupBGM];

    _pests = [NSMutableArray array];
    
    [self createPest];
    [self prepareAndMakePestCrawl];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
  
    [self playBGM];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopBGM];
}

- (BOOL)prefersStatusBarHidden {
    return YES; //返回NO表示要显示，返回YES将hiden
}

- (BOOL)prefersHomeIndicatorAutoHidden {
    return YES;
}

#pragma mark -------------------- BGM --------------------

- (void)setupBGM {

    //创建音乐文件路径
    NSString *musicFilePath = [[NSBundle mainBundle] pathForResource:@"bgm" ofType:@"mp3"];
    NSURL *musicURL = [[NSURL alloc] initFileURLWithPath:musicFilePath];
    
    AVAudioPlayer *thePlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:musicURL error:nil];
    [thePlayer prepareToPlay];
    [thePlayer setVolume:0.1];
    thePlayer.numberOfLoops = -1;//设置音乐播放次数  -1为一直循环
    
    _bgmPlayer = thePlayer;
}

- (void)playBGM {
    [_bgmPlayer play];
}

- (void)stopBGM {
    [_bgmPlayer stop];
}

#pragma mark -------------------- Pests --------------------

- (void)createPest {
    
    for (int i = 0 ; i < _pestAmounts; i++) {
        
        CGGPest *pest = [CGGPest pestSpeed:200];
        pest.playCrawlSound = NO;
        
        [_pests addObject:pest];
    }
}

- (void)prepareAndMakePestCrawl {
    
    [_pests enumerateObjectsUsingBlock:^(CGGPest *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj showInView:self.view];
        [obj putAtPoint:[self p_generateRandomOutOfScreenPestLeftTopPoint]];
        [self makePestCrawl:obj];
    }];
}

/**
 *  让制定的虫子跑起来
 *
 *  @param pest 制定的虫子
 */
- (void)makePestCrawl:(CGGPest*)pest {

    __block typeof(self) weakSelf = self;

    CGPoint distination = [self p_generateRandomDestinationPestLeftTopPointForStartPoint:pest.frame.origin];
    [pest moveToPoint:distination completion:^(BOOL finished) {
        
        if (finished) {
            //虫子自己从起点爬到终点完成整个动画，则让虫子重新爬动
            [weakSelf makePestCrawl:pest];
            return ;
        }

        //虫子未爬到终点，未完成整个动画
        __block BOOL hasShowingPest = NO;
        [_pests enumerateObjectsUsingBlock:^(CGGPest *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.isShowing) {
                hasShowingPest = YES;
                *stop = YES;
            }
        }];

        if (!hasShowingPest) {
            [weakSelf prepareAndMakePestCrawl];
        }
    }];
}

#pragma mark -------------------- Private --------------------

//生成随机的屏幕外的害虫的左上点
- (CGPoint)p_generateRandomOutOfScreenPestLeftTopPoint {
    
    /*
     |   |                           |   |
     ---------------------------------------------
     | 1 |                           | 2 |
     ---------------------------------------------
     |   |                           |   |
     |   |                           |   |
     |   |                           |   |
     |   |        Screen Area        |   |
     |   |                           |   |
     |   |                           |   |
     |   |                           |   |
     |   |                           |   |
     ----------------------------------------------
     | 3 |                           | 4 |
     ----------------------------------------------
     |   |                           |   |
     
     区域1的范围：x(-200,-100);   y(-200,-100);
     区域2的范围：x(width,width+100); y(-200,-100);
     区域3的范围：x(-200,-100);   y(height,height+100);
     区域4的范围：x(width,width+100); y(height,height+100);
     */
    
    CGGNumberRange xRange;
    CGGNumberRange yRange;
    
    if([self p_randomNumberWithRange:CGGNumberRangeMake(1, 2)] == 1) {
        
        
        //x在区域1或2，y的取值范围是（-200，height+100）
        yRange = CGGNumberRangeMake(_topYRange.min, _bottomYRange.min);
        
        if([self p_randomNumberWithRange:CGGNumberRangeMake(1, 2)] == 1) {
            xRange = _leftXRange;
        } else {
            xRange = _rightXRange;
        }
        
    } else {
        
        //y在区域1或2，y的取值范围是cv（-100，width+100）
        if([self p_randomNumberWithRange:CGGNumberRangeMake(1, 2)] == 1) {
            yRange = _bottomYRange;
        } else {
            yRange = _topYRange;
        }
        xRange = CGGNumberRangeMake(_leftXRange.min, _rightXRange.min);
    }
    
    return CGPointMake([self p_randomNumberWithRange:xRange], [self p_randomNumberWithRange:yRange]);
}

//生成随机的害虫的左上点的终点
- (CGPoint)p_generateRandomDestinationPestLeftTopPointForStartPoint:(CGPoint)startPoint {
    
    CGGNumberRange xRange;
    CGGNumberRange yRange;
    
    CGPoint original = startPoint;
    
    if (original.x < 0) {
        
        xRange = _rightXRange;
        yRange = CGGNumberRangeMake(_topYRange.max+100, _bottomYRange.min-100);
        
    } else if (original.y < 0) {
        
        xRange = CGGNumberRangeMake(_leftXRange.max+100, _rightXRange.min-100);
        yRange = _bottomYRange;
        
    } else if (original.x > kScreenWidth) {
        
        xRange = _leftXRange;
        yRange = CGGNumberRangeMake(_topYRange.max+100, _bottomYRange.min-100);
        
    } else if (original.y > kScreenHeight) {
        
        xRange = CGGNumberRangeMake(_leftXRange.max+100, _rightXRange.min-100);
        yRange = _topYRange;
    }
    
    return CGPointMake([self p_randomNumberWithRange:xRange], [self p_randomNumberWithRange:yRange]);
}

- (NSInteger)p_randomNumberWithRange:(CGGNumberRange)aRange {
    return (NSInteger)(aRange.min + (arc4random() % (aRange.max - aRange.min + 1)));
}

@end
