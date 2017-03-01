#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MFBNavigationChildrenReplacer : NSObject

- (void)replaceChildrenInNavigationController:(UINavigationController *)navigationController
                                 withChildren:(NSArray<UIViewController *> *)newChildren
                                   completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
