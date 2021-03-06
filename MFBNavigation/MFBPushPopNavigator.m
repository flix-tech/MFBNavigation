#import "MFBModalNavigator.h"
#import "MFBPushPopNavigator.h"
#import "MFBPushPopNavigator+Test.h"
#import "MFBSuspendibleUIQueue.h"


@interface MFBPushPopNavigator () <UINavigationControllerDelegate, MFBUIKitUnwindDelegate>

@end


@implementation MFBPushPopNavigator {
    id<MFBModalNavigation> _modalNavigator;
    __weak UINavigationController *_navigationController;
    MFBNavigationChildrenReplacer *_childrenReplacer;
    dispatch_block_t _transitionCompletion;
    MFBSuspendibleUIQueue *_transitionQueue;
    MFBUIKitUnwindTokenFactory *_unwindTokenFactory;
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

    _childrenReplacer = [MFBNavigationChildrenReplacer new];
    _unwindTokenFactory = [MFBUIKitUnwindTokenFactory new];

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

        if (navigationController.view.window) {
            _transitionCompletion = completion;
            [_transitionQueue suspend];

            [navigationController popToRootViewControllerAnimated:animated];
        } else {
            [_childrenReplacer replaceChildrenInNavigationController:navigationController
                                                        withChildren:@[ navigationController.viewControllers[0] ]
                                                          completion:completion];
        }
    }];
}

- (void)pushViewController:(UIViewController *)viewController
                  animated:(BOOL)animated
                completion:(dispatch_block_t)completion
{
    NSCParameterAssert(viewController != nil);

    [_transitionQueue enqueueBlock:^{
        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        if (navigationController.view.window) {
            _transitionCompletion = completion;

            [_transitionQueue suspend];
            [navigationController pushViewController:viewController animated:animated];
        } else {
            NSMutableArray<UIViewController *> *newViewControllers = [navigationController.viewControllers mutableCopy];
            [newViewControllers addObject:viewController];

            [_childrenReplacer replaceChildrenInNavigationController:navigationController
                                                        withChildren:newViewControllers
                                                          completion:completion];
        }
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

        if (navigationController.view.window) {
            [_transitionQueue suspend];
            [navigationController popToViewController:viewController animated:animated];
        } else {
            NSRange newRange = NSMakeRange(0, targetViewControllerIndex + 1);
            __auto_type newViewControllers = [navigationController.viewControllers subarrayWithRange:newRange];

            [_childrenReplacer replaceChildrenInNavigationController:navigationController
                                                        withChildren:newViewControllers
                                                          completion:nil];
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

        if (navigationController.viewControllers.count < 2) {
            if (completion) {
                completion();
            }
            return;
        }

        if (navigationController.view.window) {
            _transitionCompletion = completion;

            [_transitionQueue suspend];
            [navigationController popViewControllerAnimated:animated];
        } else {
            NSMutableArray<UIViewController *> *newViewControllers = [navigationController.viewControllers mutableCopy];
            [newViewControllers removeLastObject];

            [_childrenReplacer replaceChildrenInNavigationController:navigationController
                                                        withChildren:newViewControllers
                                                          completion:completion];
        }
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

- (id<MFBUnwindToken>)currentUnwindToken
{
    __auto_type token = [_unwindTokenFactory unwindTokenWithDelegate:self];

    [_transitionQueue enqueueBlock:^{
        __auto_type unwindTarget = _navigationController.topViewController;

        if (unwindTarget) {
            [token setUnwindTarget:unwindTarget];
        }
    }];

    return token;
}

- (void)replaceViewController:(UIViewController *)viewController
           withViewController:(UIViewController *)newViewController
                     animated:(BOOL)animated
{
    NSCParameterAssert(viewController != nil);
    NSCParameterAssert(newViewController != nil);

    [_transitionQueue enqueueBlock:^{
        __auto_type navigationController = _navigationController;

        if (!navigationController) {
            return;
        }

        NSMutableArray<UIViewController *> *newViewControllers = [navigationController.viewControllers mutableCopy];

        __auto_type index = [newViewControllers indexOfObject:viewController];

        if (index == NSNotFound) {
            return;
        }

        [newViewControllers replaceObjectAtIndex:index withObject:newViewController];

        if (navigationController.view.window) {
            [_transitionQueue suspend];
            [navigationController setViewControllers:newViewControllers animated:animated];
        } else {
            [_childrenReplacer replaceChildrenInNavigationController:navigationController
                                                        withChildren:newViewControllers
                                                          completion:nil];
        }
    }];
}

#pragma mark - Test API

- (void)setNavigationChildrenReplacer:(MFBNavigationChildrenReplacer *)childrenReplacer
{
    NSCParameterAssert(childrenReplacer != nil);

    _childrenReplacer = childrenReplacer;
}

- (void)setUnwindTokenFactory:(MFBUIKitUnwindTokenFactory *)unwindTokenFactory
{
    NSCParameterAssert(unwindTokenFactory != nil);

    _unwindTokenFactory = unwindTokenFactory;
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

    if (animated) {
        [_transitionQueue suspend];
    }
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

#pragma mark - UIKit Unwind Delegate

- (void)unwindToTarget:(UIViewController *)unwindTarget
{
    NSCParameterAssert(unwindTarget != nil);

    [self popToViewController:unwindTarget animated:YES];
}

@end
