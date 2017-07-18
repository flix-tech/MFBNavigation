@import Nimble;
@import OCMock;
@import Quick;

#import "MFBNavigationChildrenReplacer.h"
#import "MFBPushPopNavigator.h"
#import "MFBPushPopNavigator+Test.h"
#import "MFBSuspendibleUIQueue.h"

QuickSpecBegin(PushPopNavigator)

__block id modalNavigatorMock;
__block id navigationControllerMock;
__block id childrenReplacerMock;
__block MFBPushPopNavigator *pushPopNavigator;

beforeEach(^{
    navigationControllerMock = OCMStrictClassMock(UINavigationController.class);
    childrenReplacerMock = OCMStrictClassMock(MFBNavigationChildrenReplacer.class);
});

describe(@"instantiation", ^{
    it(@"sets navigation controller delegate", ^{
        OCMExpect([navigationControllerMock setDelegate:[OCMArg checkWithBlock:^(id obj) {
            expect(obj).notTo(beNil());

            return YES;
        }]]);

        pushPopNavigator = [[MFBPushPopNavigator alloc] initWithNavigationController:navigationControllerMock
                                                                     transitionQueue:nil
                                                                      modalNavigator:modalNavigatorMock];

        OCMVerifyAll(navigationControllerMock);
    });
});

describe(@"modal presentation", ^{
    beforeEach(^{
        modalNavigatorMock = OCMStrictProtocolMock(@protocol(MFBModalNavigation));
        [navigationControllerMock makeNice];

        pushPopNavigator = [[MFBPushPopNavigator alloc] initWithNavigationController:navigationControllerMock
                                                                     transitionQueue:nil
                                                                      modalNavigator:modalNavigatorMock];
    });

    it(@"forwards view controller presentation to modal navigator", ^{
        id presentedViewControllerStub = [NSObject new];
        __auto_type completionStub = ^{};

        OCMExpect([modalNavigatorMock showModalViewController:presentedViewControllerStub
                                                  animated:YES
                                                completion:completionStub]);

        [pushPopNavigator showModalViewController:presentedViewControllerStub animated:YES completion:completionStub];

        OCMVerifyAll(modalNavigatorMock);
    });

    it(@"forwards alert presentation to modal navigator", ^{
        id alertStub = [NSObject new];
        id senderStub = [NSObject new];
        __auto_type completionStub = ^{};

        OCMExpect([modalNavigatorMock showAlert:alertStub sender:senderStub animated:YES completion:completionStub]);

        [pushPopNavigator showAlert:alertStub sender:senderStub animated:YES completion:completionStub];

        OCMVerifyAll(modalNavigatorMock);
    });
});

describe(@"navigation", ^{
    __block id navigationControllerDelegate;
    __block id queueMock;

    beforeEach(^{
        queueMock = OCMStrictClassMock(MFBSuspendibleUIQueue.class);

        OCMExpect([navigationControllerMock setDelegate:[OCMArg checkWithBlock:^(id obj) {
            navigationControllerDelegate = obj;

            return YES;
        }]]);

        pushPopNavigator = [[MFBPushPopNavigator alloc] initWithNavigationController:navigationControllerMock
                                                                     transitionQueue:queueMock
                                                                      modalNavigator:modalNavigatorMock];

        [pushPopNavigator setNavigationChildrenReplacer:childrenReplacerMock];
    });

    describe(@"push", ^{
        context(@"window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn([NSObject new]);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            it(@"is enqueued", ^{
                id pushedViewControllerStub = [NSObject new];

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                [queueMock setExpectationOrderMatters:YES];
                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
                OCMExpect([queueMock suspend]);

                OCMExpect([navigationControllerMock pushViewController:pushedViewControllerStub animated:YES]);

                [pushPopNavigator pushViewController:pushedViewControllerStub animated:YES completion:nil];

                OCMVerifyAllWithDelay(queueMock, 1);

                OCMExpect([queueMock resume]);
                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:pushedViewControllerStub
                                                          animated:YES];
                OCMVerifyAllWithDelay(queueMock, 1);

                OCMVerifyAll(navigationControllerMock);
            });

            it(@"calls completion", ^{
                id pushedViewControllerStub = [NSObject new];

                id queueBlockArgument = [OCMArg invokeBlock];

                [queueMock makeNice];
                OCMExpect([queueMock enqueueBlock:queueBlockArgument]);

                [navigationControllerMock makeNice];

                __auto_type completionCalled = [self expectationWithDescription:@"completion called"];

                [pushPopNavigator pushViewController:pushedViewControllerStub animated:YES completion:^{
                    [completionCalled fulfill];
                }];
                
                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:pushedViewControllerStub
                                                          animated:YES];
                
                [self waitForExpectationsWithTimeout:1 handler:nil];
            });
        });

        context(@"no window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn(nil);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            it(@"is enqueued and delegated to children replacer", ^{
                id pushedViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ @"A", @"B" ];
                NSArray *expectedViewControllers = [viewControllersStub arrayByAddingObject:pushedViewControllerStub];

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                __auto_type completion = ^{};

                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                OCMExpect([childrenReplacerMock replaceChildrenInNavigationController:navigationControllerMock
                                                                         withChildren:expectedViewControllers
                                                                           completion:completion]);

                [pushPopNavigator pushViewController:pushedViewControllerStub animated:YES completion:completion];

                OCMVerifyAllWithDelay(childrenReplacerMock, 1);
                OCMVerifyAll(navigationControllerMock);
                OCMVerifyAll(queueMock);
            });
        });
    });

    describe(@"pop", ^{
        sharedExamples(@"only one navigation controller in the stack", ^(QCKDSLSharedExampleContext _) {
            it(@"does not suspend queue and does not touch navigation controller nor children replacer and calls completion", ^{
                NSArray *viewControllersStub = @[ @"A" ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                OCMExpect([queueMock enqueueBlock:[OCMArg invokeBlock]]);

                __block NSInteger completionCalledTimes = 0;
                [pushPopNavigator popViewControllerAnimated:YES completion:^{
                    completionCalledTimes++;
                }];

                OCMVerifyAllWithDelay(queueMock, 1);

                XCTAssertEqual(completionCalledTimes, 1);
            });
        });

        context(@"window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn([NSObject new]);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            itBehavesLike(@"only one navigation controller in the stack", ^{ return @{}; });

            it(@"is enqueued", ^{
                NSArray *viewControllersStub = @[ @"A", @"B" ];
                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                [queueMock setExpectationOrderMatters:YES];
                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
                OCMExpect([queueMock suspend]);

                OCMExpect([navigationControllerMock popViewControllerAnimated:YES]);

                [pushPopNavigator popViewControllerAnimated:YES completion:nil];

                OCMVerifyAllWithDelay(queueMock, 1);

                OCMExpect([queueMock resume]);
                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:(id) [NSObject new]
                                                          animated:YES];
                OCMVerifyAllWithDelay(queueMock, 1);
                
                OCMVerifyAll(navigationControllerMock);
            });

            it(@"calls completion", ^{
                NSArray *viewControllersStub = @[ @"A", @"B" ];
                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                id queueBlockArgument = [OCMArg invokeBlock];

                [queueMock makeNice];
                OCMExpect([queueMock enqueueBlock:queueBlockArgument]);

                [navigationControllerMock makeNice];

                __auto_type completionCalled = [self expectationWithDescription:@"completion called"];

                [pushPopNavigator popViewControllerAnimated:YES completion:^{
                    [completionCalled fulfill];
                }];

                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:(id) [NSObject new]
                                                          animated:YES];

                [self waitForExpectationsWithTimeout:1 handler:nil];
            });
        });

        context(@"no window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn(nil);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            it(@"is enqueued and delegated to children replacer", ^{
                NSArray *viewControllersStub = @[ @"A", @"B" ];
                NSArray *expectedViewControllers = @[ viewControllersStub[0] ];

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                __auto_type completion = ^{};

                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                OCMExpect([childrenReplacerMock replaceChildrenInNavigationController:navigationControllerMock
                                                                         withChildren:expectedViewControllers
                                                                           completion:completion]);

                [pushPopNavigator popViewControllerAnimated:YES completion:completion];

                OCMVerifyAllWithDelay(childrenReplacerMock, 1);
                OCMVerifyAll(navigationControllerMock);
                OCMVerifyAll(queueMock);
            });

            itBehavesLike(@"only one navigation controller in the stack", ^{ return @{}; });
        });
    });

    describe(@"pop to view controller", ^{
        sharedExamples(@"target view controller is alrady on top of navigation stack", ^(QCKDSLSharedExampleContext _) {
            it(@"does not suspend queue and does not touch navigation controller", ^{
                id targetViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ @"A", targetViewControllerStub ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);
                OCMStub([navigationControllerMock topViewController]).andReturn(targetViewControllerStub);

                OCMExpect([queueMock enqueueBlock:[OCMArg invokeBlock]]);

                [pushPopNavigator popToViewController:targetViewControllerStub animated:YES];

                OCMVerifyAllWithDelay(queueMock, 1);
            });
        });

        context(@"window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn([NSObject new]);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            itBehavesLike(@"target view controller is alrady on top of navigation stack", ^{ return @{}; });

            it(@"is enqueued & performed when navigation controller is visible", ^{
                id targetViewControllerStub = [NSObject new];
                NSArray *viewControllersStub = @[ targetViewControllerStub, @"B" ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);
                OCMStub([navigationControllerMock topViewController]).andReturn(viewControllersStub.lastObject);

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                [queueMock setExpectationOrderMatters:YES];
                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
                OCMExpect([queueMock suspend]);

                OCMExpect([(UINavigationController *) navigationControllerMock popToViewController:targetViewControllerStub animated:YES]);

                [pushPopNavigator popToViewController:targetViewControllerStub animated:YES];

                OCMVerifyAllWithDelay(queueMock, 1);

                OCMExpect([queueMock resume]);
                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:targetViewControllerStub
                                                          animated:YES];
                OCMVerifyAllWithDelay(queueMock, 1);
                
                OCMVerifyAll(navigationControllerMock);
            });
        });

        context(@"no window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn(nil);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            itBehavesLike(@"target view controller is alrady on top of navigation stack", ^{ return @{}; });

            it(@"is enqueued and delegated to children replacer", ^{
                id targetViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ @"A", targetViewControllerStub, @"B" ];
                NSArray *expectedViewControllers = [viewControllersStub subarrayWithRange:NSMakeRange(0, 2)];

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);
                OCMStub([navigationControllerMock topViewController]).andReturn(viewControllersStub.lastObject);

                OCMExpect([childrenReplacerMock replaceChildrenInNavigationController:navigationControllerMock
                                                                         withChildren:expectedViewControllers
                                                                           completion:nil]);

                [pushPopNavigator popToViewController:targetViewControllerStub animated:YES];

                OCMVerifyAllWithDelay(childrenReplacerMock, 1);
                OCMVerifyAll(navigationControllerMock);
                OCMVerifyAll(queueMock);
            });
        });
    });

    describe(@"pop to root", ^{
        sharedExamples(@"one view controller in navigation stack", ^(QCKDSLSharedExampleContext _) {
            it(@"does not suspend queue and does not touch navigation controller nor children replacer and calls completion", ^{
                NSArray *viewControllersStub = @[ @"A" ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                OCMExpect([queueMock enqueueBlock:[OCMArg invokeBlock]]);

                __block NSInteger completionCalledTimes = 0;
                [pushPopNavigator popToRootAnimated:YES completion:^{
                    completionCalledTimes++;
                }];

                OCMVerifyAllWithDelay(queueMock, 1);

                XCTAssertEqual(completionCalledTimes, 1);
            });
        });

        context(@"with window", ^{
            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn([NSObject new]);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);
            });

            itBehavesLike(@"one view controller in navigation stack", ^{ return @{}; });

            it(@"is enqueued and performed", ^{

                id targetViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ targetViewControllerStub, @"A", @"B" ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                [queueMock setExpectationOrderMatters:YES];
                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);
                OCMExpect([queueMock suspend]);
                OCMExpect([queueMock resume]);

                OCMExpect([navigationControllerMock popToRootViewControllerAnimated:YES]);

                [pushPopNavigator popToRootAnimated:YES completion:nil];

                OCMVerifyAllWithDelay(navigationControllerMock, 1);

                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:targetViewControllerStub
                                                          animated:YES];

                OCMVerifyAllWithDelay(queueMock, 1);
            });

            it(@"calls completion", ^{
                [queueMock makeNice];

                id targetViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ targetViewControllerStub, @"A", @"B" ];

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                OCMStub([queueMock enqueueBlock:queueBlockValidator]);
                OCMExpect([navigationControllerMock popToRootViewControllerAnimated:YES]);

                __block BOOL completionCalled = NO;
                [pushPopNavigator popToRootAnimated:YES completion:^{
                    expect(completionCalled).to(beFalse());
                    completionCalled = YES;
                }];

                OCMVerifyAllWithDelay(navigationControllerMock, 1);

                [navigationControllerDelegate navigationController:navigationControllerMock
                                             didShowViewController:targetViewControllerStub
                                                          animated:YES];
                
                expect(completionCalled).toEventually(beTrue());
            });
        });

        context(@"no window", ^{
            __block id viewClassMock;

            beforeEach(^{
                id viewStub = OCMStrictClassMock(UIView.class);
                OCMStub([viewStub window]).andReturn(nil);
                OCMStub([navigationControllerMock view]).andReturn(viewStub);

                viewClassMock = OCMStrictClassMock(UIView.class);
            });

            afterEach(^{
                viewClassMock = nil;
            });

            itBehavesLike(@"one view controller in navigation stack", ^{ return @{}; });

            it(@"is enqueued and delegated to children replacer", ^{
                id targetViewControllerStub = [NSObject new];

                NSArray *viewControllersStub = @[ targetViewControllerStub, @"A", @"B" ];
                NSArray *expectedViewControllers = [viewControllersStub subarrayWithRange:NSMakeRange(0, 1)];

                id queueBlockValidator = [OCMArg checkWithBlock:^(dispatch_block_t block) {
                    dispatch_async(dispatch_get_main_queue(), block);

                    return YES;
                }];

                __auto_type completion = ^{};

                OCMExpect([queueMock enqueueBlock:queueBlockValidator]);

                OCMStub([navigationControllerMock viewControllers]).andReturn(viewControllersStub);

                OCMExpect([childrenReplacerMock replaceChildrenInNavigationController:navigationControllerMock
                                                                         withChildren:expectedViewControllers
                                                                           completion:completion]);

                [pushPopNavigator popToRootAnimated:YES completion:completion];

                OCMVerifyAllWithDelay(childrenReplacerMock, 1);
                OCMVerifyAll(navigationControllerMock);
                OCMVerifyAll(queueMock);
            });
        });
    });
});

describe(@"delegate forwarding", ^{
    __block id<UINavigationControllerDelegate> internalDelegate;
    __block id viewControllerStub;

    beforeEach(^{
        viewControllerStub = [NSObject new];

        OCMStub([navigationControllerMock setDelegate:[OCMArg checkWithBlock:^(id obj) {
            internalDelegate = obj;

            return YES;
        }]]);

        pushPopNavigator = [[MFBPushPopNavigator alloc] initWithNavigationController:navigationControllerMock
                                                                     transitionQueue:nil
                                                                      modalNavigator:modalNavigatorMock];

        OCMStub([navigationControllerMock transitionCoordinator]).andReturn(OCMProtocolMock(@protocol(UIViewControllerTransitionCoordinator)));
    });

    context(@"external delegate implementing all methods", ^{
        __block id externalDelegateMock;

        beforeEach(^{
            externalDelegateMock = OCMStrictProtocolMock(@protocol(UINavigationControllerDelegate));
            pushPopNavigator.navigationControllerDelegate = externalDelegateMock;
        });

        it(@"forwards willShowViewController", ^{
            OCMExpect([externalDelegateMock navigationController:navigationControllerMock
                                          willShowViewController:viewControllerStub
                                                        animated:YES]);

            [internalDelegate navigationController:navigationControllerMock
                            willShowViewController:viewControllerStub
                                          animated:YES];

            OCMVerifyAll(externalDelegateMock);
        });

        it(@"forwards didShowViewController", ^{
            OCMExpect([externalDelegateMock navigationController:navigationControllerMock
                                           didShowViewController:viewControllerStub
                                                        animated:YES]);

            [internalDelegate navigationController:navigationControllerMock
                             didShowViewController:viewControllerStub
                                          animated:YES];

            OCMVerifyAll(externalDelegateMock);
        });

        it(@"forwards navigationControllerSupportedInterfaceOrientations", ^{
            __auto_type expectedOrientations = UIInterfaceOrientationMaskPortrait;
            if (arc4random_uniform(2) == 1) {
                expectedOrientations |= UIInterfaceOrientationMaskPortraitUpsideDown;
            }

            OCMExpect([externalDelegateMock navigationControllerSupportedInterfaceOrientations:navigationControllerMock])
            .andReturn(expectedOrientations);

            __auto_type orientations = [internalDelegate navigationControllerSupportedInterfaceOrientations:navigationControllerMock];

            expect(@(orientations)).to(be(@(expectedOrientations)));

            OCMVerifyAll(externalDelegateMock);
        });

        it(@"forwards navigationControllerPreferredInterfaceOrientationForPresentation", ^{
            __auto_type expectedOrientation = UIInterfaceOrientationUnknown + (UIInterfaceOrientation) arc4random_uniform(UIInterfaceOrientationLandscapeRight);

            OCMExpect([externalDelegateMock navigationControllerPreferredInterfaceOrientationForPresentation:navigationControllerMock])
            .andReturn(expectedOrientation);

            __auto_type orientation = [internalDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationControllerMock];

            expect(@(orientation)).to(be(@(expectedOrientation)));

            OCMVerifyAll(externalDelegateMock);
        });

        it(@"forwards interactionControllerForAnimationController", ^{
            id expectedResult = [NSObject new];
            id transitionStub = [NSObject new];

            OCMExpect([externalDelegateMock navigationController:navigationControllerMock interactionControllerForAnimationController:transitionStub])
            .andReturn(expectedResult);

            __auto_type result = [internalDelegate navigationController:navigationControllerMock interactionControllerForAnimationController:transitionStub];

            expect(result).to(be(expectedResult));

            OCMVerifyAll(externalDelegateMock);
        });

        it(@"forwards animationControllerForOperation", ^{
            id expectedResult = [NSObject new];
            __auto_type navigationOperation = arc4random_uniform(2) == 1 ? UINavigationControllerOperationPop : UINavigationControllerOperationPush;
            id fromVCStub = [NSObject new];
            id toVCStub = [NSObject new];

            OCMExpect([externalDelegateMock navigationController:navigationControllerMock
                                 animationControllerForOperation:navigationOperation
                                              fromViewController:fromVCStub
                                                toViewController:toVCStub])
            .andReturn(expectedResult);

            __auto_type result = [internalDelegate navigationController:navigationControllerMock
                                        animationControllerForOperation:navigationOperation
                                                     fromViewController:fromVCStub
                                                       toViewController:toVCStub];

            expect(result).to(be(expectedResult));

            OCMVerifyAll(externalDelegateMock);
        });
    });

    context(@"external delegate implementing notihng", ^{
        id dummyDelegate = [NSObject new];

        beforeEach(^{
            pushPopNavigator.navigationControllerDelegate = dummyDelegate;
        });

        it(@"doesn't crash on willShowViewController", ^{
            [internalDelegate navigationController:navigationControllerMock
                            willShowViewController:viewControllerStub
                                          animated:YES];
        });

        it(@"doesn't crash on didShowViewController", ^{
            [internalDelegate navigationController:navigationControllerMock
                             didShowViewController:viewControllerStub
                                          animated:YES];
        });

        it(@"doesn't forward navigationControllerSupportedInterfaceOrientations", ^{
            expect(@([internalDelegate navigationControllerSupportedInterfaceOrientations:navigationControllerMock])).to(raiseException());
        });

        it(@"forwards navigationControllerPreferredInterfaceOrientationForPresentation", ^{
            expect(@([internalDelegate navigationControllerPreferredInterfaceOrientationForPresentation:navigationControllerMock])).to(raiseException());
        });

        it(@"forwards interactionControllerForAnimationController", ^{
            id transitionStub = [NSObject new];

            expect([internalDelegate navigationController:navigationControllerMock interactionControllerForAnimationController:transitionStub]).to(raiseException());
        });

        it(@"forwards animationControllerForOperation", ^{
            __auto_type navigationOperation = UINavigationControllerOperationPop;
            id fromVCStub = [NSObject new];
            id toVCStub = [NSObject new];

            expect([internalDelegate navigationController:navigationControllerMock
                          animationControllerForOperation:navigationOperation
                                       fromViewController:fromVCStub
                                         toViewController:toVCStub]).to(raiseException());
        });
    });
});

QuickSpecEnd
