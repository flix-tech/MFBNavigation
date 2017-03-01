#import "MFBNavigationChildrenReplacer.h"

@implementation MFBNavigationChildrenReplacer

- (void)replaceChildrenInNavigationController:(UINavigationController *)navigationController
                                 withChildren:(NSArray<UIViewController *> *)newChildren
                                   completion:(nullable dispatch_block_t)completion
{
    NSCParameterAssert(navigationController != nil);
    NSCParameterAssert(newChildren != nil);

    [UIView performWithoutAnimation:^{
        [navigationController setViewControllers:newChildren animated:NO];
    }];

    if (completion) {
        completion();
    }
}

@end
