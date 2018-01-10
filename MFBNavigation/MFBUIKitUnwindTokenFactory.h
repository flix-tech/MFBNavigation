#import <Foundation/Foundation.h>

#import "MFBUIKitUnwindToken.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFBUIKitUnwindTokenFactory : NSObject

- (MFBUIKitUnwindToken *)unwindTokenWithDelegate:(id<MFBUIKitUnwindDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
