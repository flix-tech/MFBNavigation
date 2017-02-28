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
    id currentViewControllersStub = [NSObject new];
    id mappedViewControllersStub = [NSObject new];

    __block NSInteger completionCalledTimes = 0;

    OCMExpect([navigationControllerMock viewControllers]).andReturn(currentViewControllersStub);

    OCMExpect([viewClassMock performWithoutAnimation:[OCMArg checkWithBlock:^(dispatch_block_t block) {
        OCMExpect([navigationControllerMock setViewControllers:mappedViewControllersStub animated:NO])
            .andDo(^(NSInvocation *_) {
                XCTAssertEqual(completionCalledTimes, 0);
            });

        block();

        return YES;
    }]]);

    __auto_type mapper = ^(NSArray<UIViewController *> *currentViewControllers) {
        XCTAssertEqual(currentViewControllers, currentViewControllersStub);

        return mappedViewControllersStub;
    };

    [replacer replaceChildrenInNavigationController:navigationControllerMock
                                          byMapping:mapper
                                         completion:^{
                                             completionCalledTimes++;
                                         }];

    OCMVerifyAll(navigationControllerMock);
    OCMVerifyAll(viewClassMock);

    XCTAssertEqual(completionCalledTimes, 1);
});

QuickSpecEnd
