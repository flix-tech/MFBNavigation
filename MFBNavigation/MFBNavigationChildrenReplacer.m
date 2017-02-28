#import "MFBNavigationChildrenReplacer.h"

@implementation MFBNavigationChildrenReplacer

- (void)replaceChildrenInNavigationController:(UINavigationController *)navigationController
                                    byMapping:(MFBNavigationChildrenReplacerMapping)mapping
                                   completion:(nullable dispatch_block_t)completion
{
    NSCParameterAssert(mapping != nil);
    NSCParameterAssert(navigationController != nil);

    __auto_type newViewControllers = mapping(navigationController.viewControllers);

    [UIView performWithoutAnimation:^{
        [navigationController setViewControllers:newViewControllers animated:NO];
    }];

    if (completion) {
        completion();
    }
}

@end
