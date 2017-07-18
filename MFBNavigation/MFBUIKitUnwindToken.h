#import <UIKit/UIKit.h>

#import "MFBUnwindToken.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MFBUIKitUnwindDelegate

- (void)unwindToTarget:(UIViewController *)unwindTarget;

@end

@interface MFBUIKitUnwindToken : NSObject <MFBUnwindToken>

- (void)setUnwindTarget:(UIViewController *)unwindTarget;

@property (nonatomic, nullable, weak) id<MFBUIKitUnwindDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
