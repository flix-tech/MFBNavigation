#import "MFBAlertProxy.h"
#import "MFBModalNavigator.h"
#import "MFBSuspendibleUIQueue.h"

@implementation MFBModalNavigator {
    MFBSuspendibleUIQueue *_transitionQueue;
    __weak UIViewController *_viewController;
}

- (instancetype)initWithTransitionQueue:(MFBSuspendibleUIQueue *)queue viewController:(UIViewController *)viewController
{
    NSCParameterAssert(queue != nil);
    NSCParameterAssert(viewController != nil);

    self = [super init];

    if (!self) {
        return nil;
    }

    _transitionQueue = queue;
    _viewController = viewController;

    return self;
}

- (void)showModalViewController:(UIViewController *)viewController
                       animated:(BOOL)animated
                     completion:(nullable dispatch_block_t)completion
{
    NSCParameterAssert(viewController != nil);

    UIViewController *presenter = _viewController;

    if (!presenter) {
        return;
    }

    [_transitionQueue enqueueBlock:^{
        if (presenter.presentedViewController) {
            if (completion) {
                completion();
            }
            return;
        }

        [_transitionQueue suspend];

        dispatch_block_t realCompletion = [self completionForModalPresentationOrDismissalWithCompletion:completion];

        [presenter presentViewController:viewController animated:animated completion:realCompletion];

        [presenter.transitionCoordinator animateAlongsideTransition:nil
                                                         completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                                             realCompletion();
                                                         }];
    }];
}

- (void)showAlert:(id<MFBAlertProxy>)alert sender:(id)sender animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    NSCParameterAssert(alert != nil);

    UIViewController *presenter = _viewController;

    if (!presenter) {
        return;
    }

    [alert addDidDismissBlock:^{
        if (completion) {
            completion();
        }

        [_transitionQueue resume];
    }];

    [_transitionQueue enqueueBlock:^{
        [_transitionQueue suspend];

        [alert showWithSender:sender controller:presenter animated:animated completion:nil];
    }];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated completion:(nullable dispatch_block_t)completion
{
    UIViewController *presenter = _viewController;

    if (!presenter) {
        return;
    }

    [_transitionQueue enqueueBlock:^{
        if (!presenter.presentedViewController) {
            if (completion) {
                completion();
            }
            return;
        }

        [_transitionQueue suspend];

        dispatch_block_t realCompletion = [self completionForModalPresentationOrDismissalWithCompletion:completion];

        [presenter dismissViewControllerAnimated:animated completion:realCompletion];

        [presenter.transitionCoordinator animateAlongsideTransition:nil
                                                         completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                                                             realCompletion();
                                                         }];
    }];
}

#pragma mark - Private methods

- (dispatch_block_t)completionForModalPresentationOrDismissalWithCompletion:(nullable dispatch_block_t)completion
{
    // it seems that completion is called for @c -presentViewController:animated:completion even if interactive transition is
    // cancelled,
    // that's why we must keep track if completion was already called or not to be forward-compatible, because Apple may
    // eventually
    // make behaviour of present & dismiss completions consistent in regard to interactive transitions.
    __block BOOL completionCalled = NO;

    return ^{
        if (completionCalled) {
            return;
        }
        completionCalled = YES;

        [_transitionQueue resume];

        if (completion) {
            completion();
        }
    };
}

@end
