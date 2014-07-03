//
//  AwesomeMenu.h
//  AwesomeMenu
//
//  Created by Levey on 11/30/11.
//  Copyright (c) 2011 Levey & Other Contributors. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AwesomeMenuItem.h"

@protocol AwesomeMenuDelegate;

typedef CGPoint (^AwesomeMenuPointMakeBlock)(int itemIndex, int itemCount, CGPoint originPoint, CGFloat radius, CGFloat wholeAngle);

@interface AwesomeMenu : UIView <AwesomeMenuItemDelegate>

@property (nonatomic, copy) NSArray *menusArray;
@property (nonatomic, getter = isExpanding) BOOL expanding;
@property (nonatomic, weak) id<AwesomeMenuDelegate> delegate;

@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) UIImage *highlightedImage;
@property (nonatomic, strong) UIImage *contentImage;
@property (nonatomic, strong) UIImage *highlightedContentImage;

@property (nonatomic, assign) CGFloat nearRadius;
@property (nonatomic, assign) CGFloat endRadius;
@property (nonatomic, assign) CGFloat farRadius;
@property (nonatomic, assign) CGPoint startPoint;
@property (nonatomic, assign) CGFloat timeOffset;
@property (nonatomic, assign) CGFloat rotateAngle;
@property (nonatomic, assign) CGFloat menuWholeAngle;
@property (nonatomic, assign) CGFloat expandRotation;
@property (nonatomic, assign) CGFloat closeRotation;
@property (nonatomic, assign) CGFloat animationDuration;

@property (nonatomic, strong) AwesomeMenuItem *startButton;

@property (nonatomic, copy) AwesomeMenuPointMakeBlock pointMakeBlock;

- (id)initWithFrame:(CGRect)frame startItem:(AwesomeMenuItem*)startItem optionMenus:(NSArray *)aMenusArray;
- (void)expand;
- (void)shrink;

@end

@protocol AwesomeMenuDelegate <NSObject>
- (void)awesomeMenu:(AwesomeMenu *)menu didSelectIndex:(NSInteger)idx;
@optional
- (void)awesomeMenuDidFinishAnimationClose:(AwesomeMenu *)menu;
- (void)awesomeMenuDidFinishAnimationOpen:(AwesomeMenu *)menu;
- (void)awesomeMenuWillStartAnimationClose:(AwesomeMenu *)menu;
- (void)awesomeMenuWillStartAnimationOpen:(AwesomeMenu *)menu;
@end