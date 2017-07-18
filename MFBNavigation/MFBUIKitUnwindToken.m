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

    switch (_state) {
        case NavigationUnwindTokenStateIdle:
            _unwindTarget = unwindTarget;
            _state = NavigationUnwindTokenStateReady;
            break;

        case NavigationUnwindTokenStateTriggered:
            [_delegate unwindToTarget:unwindTarget];
            _state = NavigationUnwindTokenStateUnwound;
            break;
        case NavigationUnwindTokenStateReady:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Unwind target has already been set"
                                         userInfo:nil];
        case NavigationUnwindTokenStateUnwound:
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Unwind has already happened"
                                         userInfo:nil];
    }
}

- (void)unwind
{
    switch (_state) {
        case NavigationUnwindTokenStateIdle:
            _state = NavigationUnwindTokenStateTriggered;
            break;

        case NavigationUnwindTokenStateReady: {
            __auto_type unwindTarget = _unwindTarget;
            if (unwindTarget) {
                [_delegate unwindToTarget:unwindTarget];
            }
            _state = NavigationUnwindTokenStateUnwound;
            break;
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
