#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSArray<UIViewController *> *_Nonnull(^MFBNavigationChildrenReplacerMapping)(NSArray<UIViewController *> *currentViewControllers);

@interface MFBNavigationChildrenReplacer : NSObject

- (void)replaceChildrenInNavigationController:(UINavigationController *)navigationController
                                    byMapping:(MFBNavigationChildrenReplacerMapping)mapping
                                   completion:(nullable dispatch_block_t)completion;

@end

NS_ASSUME_NONNULL_END
