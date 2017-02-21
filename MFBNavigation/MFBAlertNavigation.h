#import <Foundation/Foundation.h>

@protocol MFBAlertProxy;

NS_ASSUME_NONNULL_BEGIN

@protocol MFBAlertNavigation

- (void)showAlert:(id<MFBAlertProxy>)alert
           sender:(nullable id)sender
         animated:(BOOL)animated
       completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
