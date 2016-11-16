#import <UIKit/UIKit.h>

#import "MFBPushPopNavigation.h"

@class MFBSuspendibleUIQueue;

NS_ASSUME_NONNULL_BEGIN

@interface MFBPushPopNavigator : NSObject <MFBPushPopNavigation>

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                             transitionQueue:(nullable MFBSuspendibleUIQueue *)transitionQueue
                              modalNavigator:(nullable id<MFBModalNavigation>)modalNavigator NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@property (nonatomic, nullable, weak) id<UINavigationControllerDelegate> navigationControllerDelegate;

@end

NS_ASSUME_NONNULL_END
