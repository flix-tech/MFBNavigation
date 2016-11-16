#import "MFBModalNavigator.h"
#import "MFBPushPopNavigator.h"
#import "MFBSuspendibleUIQueue.h"


@interface MFBPushPopNavigator () <UINavigationControllerDelegate>

@end


@implementation MFBPushPopNavigator {
    id<MFBModalNavigation> _modalNavigator;
    __weak UINavigationController *_navigationController;
    dispatch_block_t _transitionCompletion;
    MFBSuspendibleUIQueue *_transitionQueue;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"Please use one of the available initializers"
                                 userInfo:nil];
}

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
                             transitionQueue:(MFBSuspendibleUIQueue *)transitionQueue
                              modalNavigator:(id<MFBModalNavigation>)modalNavigator
{
    NSCParameterAssert(navigationController != nil);

    self = [super init];

    if (!self) {
        return nil;
    }

    _navigationController = navigationController;
    _navigationController.delegate = self;
    _transitionQueue = transitionQueue ?: [MFBSuspendibleUIQueue new];

    _modalNavigator = modalNavigator ?: [[MFBModalNavigator alloc] initWithTransitionQueue:_transitionQueue
                                                                            viewController:navigationController];

    return self;
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    __auto_type delegate = self.navigationControllerDelegate;

    if ([delegate respondsToSelector:aSelector]) {
        return delegate;
    }

    return [super forwardingTargetForSelector:aSelector];
}

#pragma mark - API

- (void)popToRootAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [_transitionQueue enqueueBlock:^{

        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        if (navigationController.viewControllers.count < 2) {
            if (completion) {
                completion();
            }
            return;
        }

        if (!navigationController.view.window) {
            // delegate aren't gonna be called in this case, don't suspend queue

            BOOL animationsEnabled = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            [navigationController setViewControllers:@[ navigationController.viewControllers[0] ] animated:NO];
            [UIView setAnimationsEnabled:animationsEnabled];
            if (completion) {
                completion();
            }
        } else {
            _transitionCompletion = completion;
            [_transitionQueue suspend];

            [navigationController popToRootViewControllerAnimated:animated];
        }
    }];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    NSCParameterAssert(viewController != nil);

    [_transitionQueue enqueueBlock:^{
        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        _transitionCompletion = completion;

        [_transitionQueue suspend];
        [navigationController pushViewController:viewController animated:animated];
    }];
}

- (void)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [_transitionQueue enqueueBlock:^{
        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        if (navigationController.topViewController == viewController) {
            return;
        }

        __auto_type viewControllers = navigationController.viewControllers;
        NSUInteger targetViewControllerIndex = [viewControllers indexOfObject:viewController];

        if (targetViewControllerIndex == NSNotFound) {
            return;
        }

        if (!navigationController.view.window) {
            NSRange newRange = NSMakeRange(0, targetViewControllerIndex + 1);
            __auto_type newViewControllers = [navigationController.viewControllers subarrayWithRange:newRange];

            BOOL animationsEnabled = [UIView areAnimationsEnabled];
            [UIView setAnimationsEnabled:NO];
            [navigationController setViewControllers:newViewControllers animated:NO];
            [UIView setAnimationsEnabled:animationsEnabled];
        } else {
            [_transitionQueue suspend];
            [navigationController popToViewController:viewController animated:animated];
        }
    }];
}

- (void)popViewControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [_transitionQueue enqueueBlock:^{
        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        _transitionCompletion = completion;

        [_transitionQueue suspend];
        [navigationController popViewControllerAnimated:animated];
    }];
}

- (void)showModalViewController:(UIViewController *)viewController animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [_modalNavigator showModalViewController:viewController animated:animated completion:completion];
}

- (void)showAlert:(id<MFBAlertProxy>)alert sender:(id)sender animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [_modalNavigator showAlert:alert sender:sender animated:animated completion:completion];
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated completion:(dispatch_block_t)completion
{
    [_modalNavigator dismissModalViewControllerAnimated:animated completion:completion];
}

#pragma mark - Navigation controller delegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    __auto_type delegate = self.navigationControllerDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate navigationController:navigationController willShowViewController:viewController animated:animated];
    }

    // handle special case when interactive transition is cancelled.
    // -...didShowViewController: won't be called in this case.
    [navigationController.transitionCoordinator
        animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            // nothing
        }
        completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            if (!context.isCancelled) {
                // consider deleate method called
                return;
            }

            // it's impossible to have a completion block for interactive transition, so just resume the queue.
            NSCAssert(_transitionCompletion == nil, @"There should be no completion block for interactive transition");

            [_transitionQueue resume];
        }];

    [_transitionQueue suspend];
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    dispatch_block_t transitionCompletion = _transitionCompletion;
    _transitionCompletion = nil;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (transitionCompletion) {
            transitionCompletion();
        }

        [_transitionQueue resume];
    });

    __auto_type delegate = _navigationControllerDelegate;
    if ([delegate respondsToSelector:_cmd]) {
        [delegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

@end
