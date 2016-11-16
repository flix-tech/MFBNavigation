#import <UIKit/UIKit.h>

@protocol MFBAlertProxy;

NS_ASSUME_NONNULL_BEGIN

@protocol MFBModalNavigation

- (void)showModalViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable dispatch_block_t)completion;

- (void)showAlert:(id<MFBAlertProxy>)alert
           sender:(nullable id)sender
         animated:(BOOL)animated
       completion:(nullable dispatch_block_t)completion;

- (void)dismissModalViewControllerAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
