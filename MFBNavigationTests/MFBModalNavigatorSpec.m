@import Nimble;
@import OCMock;
@import Quick;

#import "MFBAlertProxy.h"
#import "MFBModalNavigator.h"
#import "MFBSuspendibleUIQueue.h"

typedef void (^InteractiveTransitionCompletionBlock)(id<UIViewControllerTransitionCoordinatorContext>);

QuickSpecBegin(ModalNavigator)

__block id queueMock;
__block id sourceViewControllerMock;
__block MFBModalNavigator *navigator;

beforeEach(^{ @autoreleasepool {
    queueMock = OCMStrictClassMock(MFBSuspendibleUIQueue.class);
    sourceViewControllerMock = OCMClassMock(UIViewController.class);
    navigator = [[MFBModalNavigator alloc] initWithTransitionQueue:queueMock viewController:sourceViewControllerMock];
}});

describe(@"view controller presentation", ^{
    __block id presentedViewControllerStub;

    beforeEach(^{
        presentedViewControllerStub = OCMClassMock(UIViewController.class);
    });

    it(@"is enqueued", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        [queueMock setExpectationOrderMatters:YES];
        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
        OCMExpect([queueMock suspend]);
        OCMExpect([queueMock resume]);

        OCMExpect([sourceViewControllerMock presentViewController:presentedViewControllerStub
                                                         animated:YES
                                                       completion:[OCMArg invokeBlock]]);

        [navigator showModalViewController:presentedViewControllerStub animated:YES completion:nil];

        OCMVerifyAllWithDelay(queueMock, 1);
        OCMVerifyAll(sourceViewControllerMock);
    });

    it(@"handles cancellation of interactive transition", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        [queueMock setExpectationOrderMatters:YES];
        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
        OCMExpect([queueMock suspend]);
        OCMExpect([queueMock resume]);

        id transitionCoordinatorMock = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
        id transitionContextStub = [NSObject new];
        id transitionCompletionValidator = [OCMArg invokeBlockWithArgs:transitionContextStub, nil];
        OCMExpect([transitionCoordinatorMock animateAlongsideTransition:nil completion:transitionCompletionValidator]);
        OCMStub([sourceViewControllerMock transitionCoordinator]).andReturn(transitionCoordinatorMock);

        OCMExpect([sourceViewControllerMock presentViewController:presentedViewControllerStub
                                                         animated:YES
                                                       completion:[OCMArg isNotNil]]);

        [navigator showModalViewController:presentedViewControllerStub animated:YES completion:nil];

        OCMVerifyAllWithDelay(queueMock, 1);
        OCMVerifyAll(transitionCoordinatorMock);
        OCMVerifyAll(sourceViewControllerMock);
    });

    it(@"fires view controller completion at most once", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        [queueMock setExpectationOrderMatters:YES];
        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
        OCMExpect([queueMock suspend]);
        OCMExpect([queueMock resume]);

        id transitionCoordinatorMock = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
        id transitionContextStub = [NSObject new];
        id transitionCompletionValidator = [OCMArg invokeBlockWithArgs:transitionContextStub, nil];
        OCMExpect([transitionCoordinatorMock animateAlongsideTransition:nil completion:transitionCompletionValidator]);
        OCMStub([sourceViewControllerMock transitionCoordinator]).andReturn(transitionCoordinatorMock);

        OCMExpect([sourceViewControllerMock presentViewController:presentedViewControllerStub
                                                         animated:YES
                                                       completion:[OCMArg invokeBlock]]);
        
        __block NSInteger completionCalledTimes = 0;
        [navigator showModalViewController:presentedViewControllerStub animated:YES completion:^{
            completionCalledTimes++;
        }];
        
        
        OCMVerifyAllWithDelay(queueMock, 1);
        OCMVerifyAll(transitionCoordinatorMock);
        OCMVerifyAll(sourceViewControllerMock);
        expect(completionCalledTimes).to(equal(1));
    });

    it(@"fires completion even if only transition coordinator callback was executed", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        [queueMock setExpectationOrderMatters:YES];
        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
        OCMExpect([queueMock suspend]);
        OCMExpect([queueMock resume]);

        id transitionCoordinatorMock = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
        id transitionContextStub = [NSObject new];
        id transitionCompletionValidator = [OCMArg invokeBlockWithArgs:transitionContextStub, nil];
        OCMExpect([transitionCoordinatorMock animateAlongsideTransition:nil completion:transitionCompletionValidator]);
        OCMExpect([sourceViewControllerMock transitionCoordinator]).andReturn(transitionCoordinatorMock);

        OCMExpect([sourceViewControllerMock presentViewController:presentedViewControllerStub
                                                         animated:YES
                                                       completion:OCMOCK_ANY]);

        __block BOOL completionCalled = NO;
        [navigator showModalViewController:presentedViewControllerStub animated:YES completion:^{
            completionCalled = YES;
        }];


        OCMVerifyAllWithDelay(queueMock, 1);
        OCMVerifyAll(transitionCoordinatorMock);
        OCMVerifyAll(sourceViewControllerMock);
        expect(completionCalled).to(beTrue());
    });

    it(@"fires completion even if there's already presented controller and doesn't suspend the queue", ^{
        id anotherPresentedViewControllerStub = [NSObject new];
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            block();
            return YES;
        }];

        OCMStub([sourceViewControllerMock presentedViewController]).andReturn(presentedViewControllerStub);

        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

        __block BOOL completionCalled = NO;
        [navigator showModalViewController:anotherPresentedViewControllerStub animated:YES completion:^{
            completionCalled = YES;
        }];

        OCMVerifyAll(queueMock);
        expect(completionCalled).to(beTrue());
    });
});

describe(@"view controller dismissal", ^{
    it(@"fires completion even if there's nothing to dismiss and doesn't suspend the queue", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

        __block BOOL completionCalled = NO;
        [navigator dismissModalViewControllerAnimated:YES completion:^{
            completionCalled = YES;
        }];

        OCMVerifyAllWithDelay(queueMock, 1);
        expect(completionCalled).toEventually(beTrue());
    });

    it(@"fires completion even if only transition coordinator callback was executed", ^{
        id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
            dispatch_async(dispatch_get_main_queue(), block);

            return YES;
        }];

        [queueMock setExpectationOrderMatters:YES];
        OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
        OCMExpect([queueMock suspend]);
        OCMExpect([queueMock resume]);

        id transitionCoordinatorMock = OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator));
        id transitionContextStub = [NSObject new];
        id transitionCompletionValidator = [OCMArg invokeBlockWithArgs:transitionContextStub, nil];
        OCMExpect([transitionCoordinatorMock animateAlongsideTransition:nil completion:transitionCompletionValidator]);
        OCMExpect([sourceViewControllerMock transitionCoordinator]).andReturn(transitionCoordinatorMock);
        OCMExpect([sourceViewControllerMock presentedViewController]).andReturn([NSObject new]);
        OCMExpect([sourceViewControllerMock dismissViewControllerAnimated:YES
                                                               completion:OCMOCK_ANY]);

        __block BOOL completionCalled = NO;
        [navigator dismissModalViewControllerAnimated:YES completion:^{
            completionCalled = YES;
        }];

        OCMVerifyAllWithDelay(queueMock, 1);
        OCMVerifyAll(transitionCoordinatorMock);
        OCMVerifyAll(sourceViewControllerMock);
        expect(completionCalled).to(beTrue());
    });
});

describe(@"alert presentation", ^{
    __block id alertMock;

    beforeEach(^{
        alertMock = OCMStrictProtocolMock(@protocol(MFBAlertProxy));
    });

    it(@"does nothing after source view controller deallocation", ^{
        [alertMock makeNice];

        sourceViewControllerMock = nil;

        [navigator showAlert:alertMock sender:nil animated:YES completion:nil];
    });

    context(@"source view controller alive", ^{
        __block dispatch_block_t didDismissBlock;

        beforeEach(^{
            OCMExpect([alertMock addDidDismissBlock:[OCMArg checkWithBlock:^(id obj) {
                expect(obj).notTo(beNil());

                didDismissBlock = obj;
                return YES;
            }]]);
        });

        afterEach(^{
            OCMVerifyAll(alertMock);
        });

        it(@"is enqueued", ^{
            id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                    didDismissBlock();
                });

                return YES;
            }];

            [queueMock setExpectationOrderMatters:YES];
            OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
            OCMExpect([queueMock suspend]);
            OCMExpect([queueMock resume]);

            OCMExpect([alertMock showWithSender:nil controller:sourceViewControllerMock animated:YES completion:nil]);

            [navigator showAlert:alertMock sender:nil animated:YES completion:nil];

            OCMVerifyAllWithDelay(queueMock, 1);
            OCMVerifyAll(alertMock);
        });

        it(@"calls completion", ^{
            id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    block();
                    didDismissBlock();
                });

                return YES;
            }];

            OCMStub([queueMock enqueueBlock:queueBlockValidator]);
            OCMStub([queueMock suspend]);
            OCMStub([queueMock resume]);

            [alertMock makeNice];

            __auto_type completionCalled = [self expectationWithDescription:@"completion called"];
            [navigator showAlert:alertMock sender:nil animated:YES completion:^{
                [completionCalled fulfill];
            }];

            [self waitForExpectationsWithTimeout:1 handler:nil];
        });
    });
});

QuickSpecEnd
