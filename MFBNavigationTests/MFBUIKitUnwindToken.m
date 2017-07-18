@import Nimble;
@import OCMock;
@import Quick;

#import "MFBUIKitUnwindToken.h"

QuickSpecBegin(UIKitUnwindToken)

__block MFBUIKitUnwindToken *token;
__block id unwindTarget;
__block id unwindDelegateMock;

beforeEach(^{
    token = [MFBUIKitUnwindToken new];
    unwindTarget = [NSObject new];
    unwindDelegateMock = OCMStrictProtocolMock(@protocol(MFBUIKitUnwindDelegate));
    token.delegate = unwindDelegateMock;
});

context(@"has unwind target", ^{
    beforeEach(^{
        [token setUnwindTarget:unwindTarget];
    });

    it(@"unwinds immediately when asked to", ^{
        OCMExpect([unwindDelegateMock unwindToTarget:unwindTarget]);

        [token unwind];

        OCMVerifyAll(unwindDelegateMock);
    });
});

context(@"triggered", ^{
    beforeEach(^{
        [token unwind];
    });

    it(@"unwinds upon setting unwind target", ^{
        OCMExpect([unwindDelegateMock unwindToTarget:unwindTarget]);

        [token setUnwindTarget:unwindTarget];

        OCMVerifyAll(unwindDelegateMock);
    });
});

QuickSpecEnd
