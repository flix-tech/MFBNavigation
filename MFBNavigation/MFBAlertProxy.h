#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol MFBAlertProxy

- (void)showWithSender:(nullable id)sender
            controller:(nullable UIViewController *)controller
              animated:(BOOL)animated
            completion:(nullable dispatch_block_t)completion;

- (void)addDidDismissBlock:(dispatch_block_t)didDismissBlock;

@end

NS_ASSUME_NONNULL_END
