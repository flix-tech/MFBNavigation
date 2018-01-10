#import "MFBUIKitUnwindTokenFactory.h"

@implementation MFBUIKitUnwindTokenFactory

- (MFBUIKitUnwindToken *)unwindTokenWithDelegate:(id<MFBUIKitUnwindDelegate>)delegate
{
    NSCParameterAssert(delegate != nil);

    __auto_type token = [MFBUIKitUnwindToken new];
    token.delegate = delegate;
    return token;
}

@end
