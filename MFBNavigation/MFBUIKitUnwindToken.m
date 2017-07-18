#import "MFBUIKitUnwindToken.h"

typedef NS_ENUM(NSInteger, NavigationUnwindTokenState) {
    NavigationUnwindTokenStateIdle = 0,
    NavigationUnwindTokenStateReady,
    NavigationUnwindTokenStateTriggered,
    NavigationUnwindTokenStateUnwound,
};

@implementation MFBUIKitUnwindToken

#pragma mark - API

- (void)setUnwindTarget:(UIViewController *)unwindTarget
{
    NSCParameterAssert(unwindTarget != nil);
}

- (void)unwind
{

}

@end
