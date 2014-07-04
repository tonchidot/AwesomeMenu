//
//  AwesomeMenu.m
//  AwesomeMenu
//
//  Created by Levey on 11/30/11.
//  Copyright (c) 2011 Levey & Other Contributors. All rights reserved.
//

#import "AwesomeMenu.h"
#import <QuartzCore/QuartzCore.h>

static CGFloat const kAwesomeMenuDefaultNearRadius = 110.0f;
static CGFloat const kAwesomeMenuDefaultEndRadius = 120.0f;
static CGFloat const kAwesomeMenuDefaultFarRadius = 140.0f;
static CGFloat const kAwesomeMenuDefaultStartPointX = 160.0;
static CGFloat const kAwesomeMenuDefaultStartPointY = 240.0;
static CGFloat const kAwesomeMenuDefaultTimeOffset = 0.036f;
static CGFloat const kAwesomeMenuDefaultRotateAngle = 0.0;
static CGFloat const kAwesomeMenuDefaultMenuWholeAngle = M_PI * 2;
static CGFloat const kAwesomeMenuDefaultExpandRotation = M_PI;
static CGFloat const kAwesomeMenuDefaultCloseRotation = M_PI * 2;
static CGFloat const kAwesomeMenuDefaultAnimationDuration = 0.5f;
static CGFloat const kAwesomeMenuStartMenuDefaultAnimationDuration = 0.3f;

@interface AwesomeMenu ()
- (void)_expand;
- (void)_close;
- (void)_setMenu;
- (CAAnimationGroup *)_blowupAnimationAtPoint:(CGPoint)p;
- (CAAnimationGroup *)_shrinkAnimationAtPoint:(CGPoint)p;
@end

@implementation AwesomeMenu {
    NSArray *_menusArray;
    int _flag;
    NSTimer *_timer;
    AwesomeMenuItem *_startButton;
    
    id<AwesomeMenuDelegate> __weak _delegate;
    BOOL _isAnimating;
}

@synthesize nearRadius, endRadius, farRadius, timeOffset, rotateAngle, menuWholeAngle, startPoint, expandRotation, closeRotation, animationDuration;
@synthesize expanding = _expanding;
@synthesize delegate = _delegate;
@synthesize menusArray = _menusArray;

#pragma mark - Initialization & Cleaning up
- (id)initWithFrame:(CGRect)frame startItem:(AwesomeMenuItem*)startItem optionMenus:(NSArray *)aMenusArray
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
		
		self.nearRadius = kAwesomeMenuDefaultNearRadius;
		self.endRadius = kAwesomeMenuDefaultEndRadius;
		self.farRadius = kAwesomeMenuDefaultFarRadius;
		self.timeOffset = kAwesomeMenuDefaultTimeOffset;
		self.rotateAngle = kAwesomeMenuDefaultRotateAngle;
		self.menuWholeAngle = kAwesomeMenuDefaultMenuWholeAngle;
		self.startPoint = CGPointMake(kAwesomeMenuDefaultStartPointX, kAwesomeMenuDefaultStartPointY);
        self.expandRotation = kAwesomeMenuDefaultExpandRotation;
        self.closeRotation = kAwesomeMenuDefaultCloseRotation;
        self.animationDuration = kAwesomeMenuDefaultAnimationDuration;
        
        self.pointMakeBlock = ^(int itemIndex, int itemCount, AwesomeMenu* awesomeMenu, AwesomeMenuPointMakeAt pointAt) {
            CGFloat radius = [awesomeMenu radiusOfPointAt:pointAt];
            CGPoint beforeRotatePoint = CGPointMake(awesomeMenu.startPoint.x + radius * sinf(itemIndex * awesomeMenu.menuWholeAngle / (itemCount - 1)),
                                                    awesomeMenu.startPoint.y - radius * cosf(itemIndex * awesomeMenu.menuWholeAngle / (itemCount - 1)));
            return [awesomeMenu rotateCGPointAroundCenter:beforeRotatePoint center:awesomeMenu.startPoint angle:awesomeMenu.rotateAngle];
        };
        
        self.menusArray = aMenusArray;
        
        // assign startItem to "Add" Button.
        _startButton = startItem;
        _startButton.delegate = self;
        _startButton.center = self.startPoint;
        [self addSubview:_startButton];
    }
    return self;
}


#pragma mark - Getters & Setters

- (void)setStartPoint:(CGPoint)aPoint
{
    startPoint = aPoint;
    _startButton.center = aPoint;
}

#pragma mark - images

- (void)setImage:(UIImage *)image {
	_startButton.image = image;
}

- (UIImage*)image {
	return _startButton.image;
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
	_startButton.highlightedImage = highlightedImage;
}

- (UIImage*)highlightedImage {
	return _startButton.highlightedImage;
}


- (void)setContentImage:(UIImage *)contentImage {
	_startButton.contentImageView.image = contentImage;
}

- (UIImage*)contentImage {
	return _startButton.contentImageView.image;
}

- (void)setHighlightedContentImage:(UIImage *)highlightedContentImage {
	_startButton.contentImageView.highlightedImage = highlightedContentImage;
}

- (UIImage*)highlightedContentImage {
	return _startButton.contentImageView.highlightedImage;
}


                               
#pragma mark - UIView's methods
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    // if the menu state is expanding (expanded), everywhere can be touch
    // otherwise, only the add button are can be touch
    if (!_isAnimating && YES == _expanding)
    {
        return YES;
    }
    else
    {
        return CGRectContainsPoint(_startButton.frame, point);
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // if the menu is animating, prevent toggling
    if (_isAnimating)
    {
        return;
    }
    self.expanding = !self.isExpanding;
}

- (void)toggleExpansion
{
    self.expanding = !self.isExpanding;
}

- (void)expand
{
    self.expanding = YES;
}

- (void)shrink
{
    self.expanding = NO;
}

- (CGFloat)radiusOfPointAt:(AwesomeMenuPointMakeAt)pointAt
{
    switch (pointAt) {
        case kAwesomeMenuPointMakeAtEndPoint:
            return endRadius;
        case kAwesomeMenuPointMakeAtNearPoint:
            return nearRadius;
        case KAwesomeMenuPointMakeAtFarPoint:
            return farRadius;
    }
}

- (CGPoint)rotateCGPointAroundCenter:(CGPoint)point center:(CGPoint)center angle:(float)angle
{
    CGAffineTransform translation = CGAffineTransformMakeTranslation(center.x, center.y);
    CGAffineTransform rotation = CGAffineTransformMakeRotation(angle);
    CGAffineTransform transformGroup = CGAffineTransformConcat(CGAffineTransformConcat(CGAffineTransformInvert(translation), rotation), translation);
    return CGPointApplyAffineTransform(point, transformGroup);
}

#pragma mark - AwesomeMenuItem delegates
- (void)AwesomeMenuItemTouchesBegan:(AwesomeMenuItem *)item
{
}
- (void)AwesomeMenuItemTouchesEnd:(AwesomeMenuItem *)item
{
    if (item == _startButton) 
    {
        [self toggleExpansion];
        return;
    }
    // blowup the selected menu button
    CAAnimationGroup *blowup = [self _blowupAnimationAtPoint:item.center];
    item.layer.opacity = 0.f;
    [item.layer addAnimation:blowup forKey:@"blowup"];
    item.center = item.startPoint;
    
    // shrink other menu buttons
    for (int i = 0; i < [_menusArray count]; i ++)
    {
        AwesomeMenuItem *otherItem = [_menusArray objectAtIndex:i];
        CAAnimationGroup *shrink = [self _shrinkAnimationAtPoint:otherItem.center];
        if (otherItem.tag == item.tag) {
            continue;
        }
        otherItem.layer.opacity = 0.f;
        [otherItem.layer addAnimation:shrink forKey:@"shrink"];

        otherItem.center = otherItem.startPoint;
    }
    _expanding = NO;
    
    // rotate start button
    float angle = self.isExpanding ? -M_PI_4 : 0.0f;
    [UIView animateWithDuration:animationDuration animations:^{
        _startButton.transform = CGAffineTransformMakeRotation(angle);
    }];
    
    if ([_delegate respondsToSelector:@selector(awesomeMenu:didSelectIndex:)])
    {
        [_delegate awesomeMenu:self didSelectIndex:item.tag - 1000];
    }
}

#pragma mark - Instant methods
- (void)setMenusArray:(NSArray *)aMenusArray
{
    if (aMenusArray == _menusArray)
    {
        return;
    }
    _menusArray = [aMenusArray copy];
    
    
    // clean subviews
    for (UIView *v in self.subviews) 
    {
        if (v.tag >= 1000) 
        {
            [v removeFromSuperview];
        }
    }
}


- (void)_setMenu {
	int count = [_menusArray count];
    for (int i = 0; i < count; i ++)
    {
        AwesomeMenuItem *item = [_menusArray objectAtIndex:i];
        item.tag = 1000 + i;
        item.startPoint = startPoint;
        
        // avoid overlap
        if (menuWholeAngle >= M_PI * 2) {
            menuWholeAngle = menuWholeAngle - menuWholeAngle / count;
        }
        item.endPoint = self.pointMakeBlock(i, count, self, kAwesomeMenuPointMakeAtEndPoint);
        item.nearPoint = self.pointMakeBlock(i, count, self, kAwesomeMenuPointMakeAtNearPoint);
        item.farPoint = self.pointMakeBlock(i, count, self, KAwesomeMenuPointMakeAtFarPoint);
        item.center = item.startPoint;
        item.layer.opacity = 0.f;
        item.delegate = self;
		[self insertSubview:item belowSubview:_startButton];
    }
}

- (BOOL)isExpanding
{
    return _expanding;
}

- (void)setExpanding:(BOOL)expanding
{
	// toggle menu on tapping start button
	if (_expanding == expanding) {
		return;
	}
	if (expanding) {
		[self _setMenu];
	}
    _expanding = expanding;
    
    // rotate add button
    float angle = self.isExpanding ? -M_PI_4 : 0.0f;
    [UIView animateWithDuration:kAwesomeMenuStartMenuDefaultAnimationDuration animations:^{
        _startButton.transform = CGAffineTransformMakeRotation(angle);
    }];
    
    // expand or close animation
    if (!_timer) 
    {
        _flag = self.isExpanding ? 0 : ([_menusArray count] - 1);
        SEL selector = self.isExpanding ? @selector(_expand) : @selector(_close);

        // Adding timer to runloop to make sure UI event won't block the timer from firing
        _timer = [NSTimer timerWithTimeInterval:timeOffset target:self selector:selector userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        _isAnimating = YES;
    }
}
#pragma mark - Private methods
- (void)_expand
{
	
    if (_flag == [_menusArray count])
    {
        _isAnimating = NO;
        [_timer invalidate];
        _timer = nil;
        return;
    }
    
    int tag = 1000 + _flag;
    AwesomeMenuItem *item = (AwesomeMenuItem *)[self viewWithTag:tag];
    
    CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.values = @[@(expandRotation), @(0.0f)];
    rotateAnimation.duration = animationDuration;
    rotateAnimation.keyTimes = @[@(.3), @(.4)];
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.duration = animationDuration;
    positionAnimation.values = @[[NSValue valueWithCGPoint:item.startPoint],
                                 [NSValue valueWithCGPoint:item.farPoint],
                                 [NSValue valueWithCGPoint:item.nearPoint],
                                 [NSValue valueWithCGPoint:item.endPoint]];
    
    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.duration = animationDuration;
    alphaAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    alphaAnimation.fromValue = @(0.f);
    alphaAnimation.toValue = @(1.f);

    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = @[positionAnimation, rotateAnimation, alphaAnimation];
    animationgroup.duration = animationDuration;
    animationgroup.fillMode = kCAFillModeForwards;
    animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animationgroup.delegate = self;
    if(_flag == [_menusArray count] - 1){
        [animationgroup setValue:@"expandFirstAnimation" forKey:@"id"];
    }else if(_flag == 0){
        [animationgroup setValue:@"expandLastAnimation" forKey:@"id"];
    }
    
    item.layer.opacity = 1.f;
    [item.layer addAnimation:animationgroup forKey:@"Expand"];
    item.center = item.endPoint;
    
    _flag ++;
    
}

- (void)_close
{
    if (_flag == -1)
    {
        _isAnimating = NO;
        [_timer invalidate];
        _timer = nil;
        return;
    }
    
    int tag = 1000 + _flag;
     AwesomeMenuItem *item = (AwesomeMenuItem *)[self viewWithTag:tag];
    
    CAKeyframeAnimation *rotateAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.values = @[@(0.0f), @(closeRotation), @(0.0f)];
    rotateAnimation.duration = animationDuration;
    rotateAnimation.keyTimes = @[@(.0), @(.4), @(.5)];
    
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.duration = animationDuration;
    positionAnimation.values = @[[NSValue valueWithCGPoint:item.endPoint],
                                 [NSValue valueWithCGPoint:item.farPoint],
                                 [NSValue valueWithCGPoint:item.startPoint]];

    CABasicAnimation *alphaAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    alphaAnimation.duration = animationDuration;
    alphaAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    alphaAnimation.fromValue = @(1.f);
    alphaAnimation.toValue = @(0.f);

    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = @[positionAnimation, rotateAnimation, alphaAnimation];
    animationgroup.duration = animationDuration;
    animationgroup.fillMode = kCAFillModeForwards;
    animationgroup.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animationgroup.delegate = self;
    if(_flag == [_menusArray count] - 1){
        [animationgroup setValue:@"closeFirstAnimation" forKey:@"id"];
    }else if(_flag == 0){
        [animationgroup setValue:@"closeLastAnimation" forKey:@"id"];
    }
    
    item.layer.opacity = 0.f;
    [item.layer addAnimation:animationgroup forKey:@"Close"];
    item.center = item.startPoint;

    _flag --;
}
- (void)animationDidStart:(CAAnimation *)anim {
    if([[anim valueForKey:@"id"] isEqual:@"expandLastAnimation"]) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(awesomeMenuWillStartAnimationOpen:)]){
            [self.delegate awesomeMenuWillStartAnimationOpen:self];
        }
    }
    if([[anim valueForKey:@"id"] isEqual:@"closeFirstAnimation"]) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(awesomeMenuWillStartAnimationClose:)]){
            [self.delegate awesomeMenuWillStartAnimationClose:self];
        }
    }
}
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    if([[anim valueForKey:@"id"] isEqual:@"closeLastAnimation"]) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(awesomeMenuDidFinishAnimationClose:)]){
            [self.delegate awesomeMenuDidFinishAnimationClose:self];
        }
    }
    if([[anim valueForKey:@"id"] isEqual:@"expandFirstAnimation"]) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(awesomeMenuDidFinishAnimationOpen:)]){
            [self.delegate awesomeMenuDidFinishAnimationOpen:self];
        }
    }
}
- (CAAnimationGroup *)_blowupAnimationAtPoint:(CGPoint)p
{
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.values = @[[NSValue valueWithCGPoint:p]];
    positionAnimation.keyTimes = @[@(.3)];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(2, 2, 1)];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue  = @(1.0f);
    opacityAnimation.toValue  = @(0.0f);
    
    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = @[positionAnimation, scaleAnimation, opacityAnimation];
    animationgroup.duration = animationDuration;
    animationgroup.fillMode = kCAFillModeForwards;

    return animationgroup;
}

- (CAAnimationGroup *)_shrinkAnimationAtPoint:(CGPoint)p
{
    CAKeyframeAnimation *positionAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    positionAnimation.values = @[[NSValue valueWithCGPoint:p]];
    positionAnimation.keyTimes = @[@(.3)];
    
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.01, .01, 1)];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    opacityAnimation.fromValue  = @(1.0f);
    opacityAnimation.toValue  = @(0.0f);
    
    CAAnimationGroup *animationgroup = [CAAnimationGroup animation];
    animationgroup.animations = @[positionAnimation, scaleAnimation, opacityAnimation];
    animationgroup.duration = animationDuration;
    animationgroup.fillMode = kCAFillModeForwards;
    
    return animationgroup;
}


@end
