#import "MFBPushPopNavigator.h"

#import "MFBNavigationChildrenReplacer.h"
#import "MFBUIKitUnwindTokenFactory.h"

@interface MFBPushPopNavigator (Test)

- (void)setNavigationChildrenReplacer:(MFBNavigationChildrenReplacer *)childrenReplacer;
- (void)setUnwindTokenFactory:(MFBUIKitUnwindTokenFactory *)unwindTokenFactory;

@end
