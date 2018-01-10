#import <XCTest/XCTest.h>

#import "MFBAlertController.h"

__attribute__((annotate("returns_localized_nsstring"))) static NSString *AlertTitle(void)
{
    return @"whatever";
}

__attribute__((annotate("returns_localized_nsstring"))) static NSString *AlertMessage(void)
{
    return @"hello world";
}

@interface MFBAlertControllerTests : XCTestCase

@end

@implementation MFBAlertControllerTests {
    MFBAlertController *_alertController;
}

- (void)setUp
{
    [super setUp];

    _alertController = [MFBAlertController alertControllerWithTitle:AlertTitle()
                                                            message:AlertMessage()
                                                     preferredStyle:UIAlertControllerStyleAlert];
}

- (void)test_invokesDismissBlocksAfterDisappearingAndReleasesThem
{
    id objectKeptByBlock;

    @autoreleasepool {
        __block NSInteger block1InvocationCount = 0;
        __block NSInteger block2InvocationCount = 0;

        objectKeptByBlock = [NSObject new];

        __auto_type block1 = ^{
            __unused id captured = objectKeptByBlock;
            block1InvocationCount++;
        };

        __auto_type block2 = ^{
            block2InvocationCount++;
        };

        [_alertController addDidDismissBlock:block1];
        [_alertController addDidDismissBlock:block2];

        [_alertController viewDidDisappear:YES];

        XCTAssertEqual(block1InvocationCount, 1);
        XCTAssertEqual(block2InvocationCount, 1);

        block1 = block2 = nil;
    }

    __weak id weakObjectKeptByBlock = objectKeptByBlock;
    objectKeptByBlock = nil;

    XCTAssertNil(weakObjectKeptByBlock);
}

@end
