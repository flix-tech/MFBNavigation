#import <Foundation/Foundation.h>

#import "MFBModalNavigation.h"

@class MFBSuspendibleUIQueue;

NS_ASSUME_NONNULL_BEGIN

@interface MFBModalNavigator : NSObject <MFBModalNavigation>

- (instancetype)initWithTransitionQueue:(MFBSuspendibleUIQueue *)queue viewController:(UIViewController *)viewController;

@end

NS_ASSUME_NONNULL_END
