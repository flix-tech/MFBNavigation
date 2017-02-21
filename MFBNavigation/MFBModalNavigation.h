#import <UIKit/UIKit.h>

#import "MFBAlertNavigation.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MFBModalNavigation <MFBAlertNavigation>

- (void)showModalViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable dispatch_block_t)completion;

- (void)dismissModalViewControllerAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
