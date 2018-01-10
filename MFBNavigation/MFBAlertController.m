//
//  MFBAlertController.m
//  MFBUIKit
//
//  Created by Nikolay Kasyanov on 18.12.17.
//

#import "MFBAlertController.h"

@interface MFBAlertController ()

@end

@implementation MFBAlertController {
    NSMutableArray<dispatch_block_t> *_didDismissBlocks;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    for (dispatch_block_t block in _didDismissBlocks) {
        block();
    }
    _didDismissBlocks = nil;
}

#pragma mark - API

- (void)showWithSender:(id)sender
            controller:(UIViewController *)controller
              animated:(BOOL)animated
            completion:(dispatch_block_t)completion
{
    NSCParameterAssert(controller != nil);
    NSCAssert(completion == nil, @"Completion block is deprecated and is no longer supported");

    [controller presentViewController:self animated:animated completion:nil];
}

- (void)addDidDismissBlock:(dispatch_block_t)didDismissBlock
{
    NSCParameterAssert(didDismissBlock != nil);

    if (!_didDismissBlocks) {
        _didDismissBlocks = [NSMutableArray<dispatch_block_t> arrayWithObject:didDismissBlock];
    } else {
        [_didDismissBlocks addObject:didDismissBlock];
    }
}

@end
