#import <UIKit/UIKit.h>

#import "MFBModalNavigation.h"
#import "MFBUnwindToken.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MFBPushPopNavigation <MFBModalNavigation>

- (id<MFBUnwindToken>)pushViewController:(UIViewController *)viewController
                                animated:(BOOL)animated
                              completion:(nullable dispatch_block_t)completion;

- (void)popViewControllerAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;
- (void)popToRootAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;
- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
