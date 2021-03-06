//
//  UIView+DDGSlideOverMenuController.h
//  DuckDuckGo
//
//  Created by Mic Pringle on 27/03/2014.
//
//

#import <UIKit/UIKit.h>

typedef void(^DDGViewInspectionBlock)(UIView *view, BOOL *stop);

@interface UIView (DDGSlideOverMenuController)

- (void)inspectViewHierarchy:(DDGViewInspectionBlock)block;
- (BOOL)shouldCauseMenuPanGestureToFail;
- (UIImage *)snapshotImageAfterScreenUpdates:(BOOL)afterUpdates adjustBoundsForStatusBar:(BOOL)adjustBounds;

@end
