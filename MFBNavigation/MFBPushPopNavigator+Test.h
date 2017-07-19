#import "MFBPushPopNavigator.h"

#import "MFBNavigationChildrenReplacer.h"
#import "MFBUIKitUnwindTokenFactory.h"

NS_ASSUME_NONNULL_BEGIN

@interface MFBPushPopNavigator (Test)

- (void)setNavigationChildrenReplacer:(MFBNavigationChildrenReplacer *)childrenReplacer;
- (void)setUnwindTokenFactory:(MFBUIKitUnwindTokenFactory *)unwindTokenFactory;

@end

NS_ASSUME_NONNULL_END
