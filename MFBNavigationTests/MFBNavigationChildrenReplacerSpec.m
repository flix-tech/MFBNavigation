#import <OCMock/OCMock.h>
#import <Quick/Quick.h>
#import <XCTest/XCTest.h>

#import "MFBNavigationChildrenReplacer.h"

QuickSpecBegin(NavigationChildrenReplacer)

__block id navigationControllerMock;
__block id viewClassMock;

__block MFBNavigationChildrenReplacer *replacer;

beforeEach(^{
    viewClassMock = OCMStrictClassMock(UIView.class);
    navigationControllerMock = OCMStrictClassMock(UINavigationController.class);

    replacer = [MFBNavigationChildrenReplacer new];
});

it(@"replaces view controllers in animationless manner after applying transformation to current ones and calls completion thereafter", ^{
    id newViewControllersStub = [NSObject new];

    __block NSInteger completionCalledTimes = 0;

    OCMExpect([viewClassMock performWithoutAnimation:[OCMArg checkWithBlock:^(dispatch_block_t block) {
        OCMExpect([navigationControllerMock setViewControllers:newViewControllersStub animated:NO])
            .andDo(^(NSInvocation *_) {
                XCTAssertEqual(completionCalledTimes, 0);
            });

        block();

        return YES;
    }]]);

    [replacer replaceChildrenInNavigationController:navigationControllerMock
                                       withChildren:newViewControllersStub
                                         completion:^{
                                             completionCalledTimes++;
                                         }];

    OCMVerifyAll(navigationControllerMock);
    OCMVerifyAll(viewClassMock);

    XCTAssertEqual(completionCalledTimes, 1);
});

QuickSpecEnd
