#import "MFBUIKitUnwindToken.h"

typedef NS_ENUM(NSInteger, NavigationUnwindTokenState) {
    NavigationUnwindTokenStateIdle = 0,
    NavigationUnwindTokenStateReady,
    NavigationUnwindTokenStateTriggered,
    NavigationUnwindTokenStateUnwound,
};

@implementation MFBUIKitUnwindToken {
    NavigationUnwindTokenState _state;

    __weak UIViewController *_unwindTarget;
}

#pragma mark - API

- (void)setUnwindTarget:(UIViewController *)unwindTarget
{
    NSCParameterAssert(unwindTarget != nil);

    NSCAssert(_state != NavigationUnwindTokenStateReady, @"Unwind target has already been set");
    NSCAssert(_state != NavigationUnwindTokenStateUnwound, @"Unwind has already happened");

    if (_state == NavigationUnwindTokenStateTriggered) {
        [_delegate unwindToTarget:unwindTarget];
        _state = NavigationUnwindTokenStateUnwound;
    } else {
        _unwindTarget = unwindTarget;
        _state = NavigationUnwindTokenStateReady;
    }
}

- (void)unwind
{
    switch (_state) {
        case NavigationUnwindTokenStateIdle:
            _state = NavigationUnwindTokenStateTriggered;
            return;

        case NavigationUnwindTokenStateReady: {
            __auto_type unwindTarget = _unwindTarget;
            if (unwindTarget) {
                [_delegate unwindToTarget:unwindTarget];
            }
            _state = NavigationUnwindTokenStateUnwound;
            return;
        }
        case NavigationUnwindTokenStateTriggered:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Unwind has already been triggered"
                                         userInfo:nil];
        case NavigationUnwindTokenStateUnwound:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Unwind has already happened"
                                         userInfo:nil];
    }
}

@end
