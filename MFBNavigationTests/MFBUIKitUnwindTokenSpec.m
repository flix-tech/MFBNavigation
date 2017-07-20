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

    context(@"target deallocated", ^{
        beforeEach(^{
            unwindTarget = nil;
        });

        it(@"does nothing", ^{
            [token unwind];
        });
    });

    it(@"throws if target is set once more", ^{
        XCTAssertThrows([token setUnwindTarget:unwindTarget]);
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

context(@"unwound", ^{
    beforeEach(^{
        [unwindDelegateMock makeNice];
        [token setUnwindTarget:unwindTarget];
        [token unwind];
        [unwindDelegateMock makeStrict];
    });

    it(@"unwind is idempotent", ^{
        [token unwind];
    });
});

QuickSpecEnd
