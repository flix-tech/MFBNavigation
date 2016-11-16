#import "MFBSuspendibleUIQueue.h"


@interface MFBSuspendibleUIQueue ()

@property (nonatomic, strong, readonly) dispatch_queue_t queue;
@property (nonatomic) BOOL suspended;

@end


@implementation MFBSuspendibleUIQueue

- (instancetype)init
{
    self = [super init];

    if (!self) {
        return nil;
    }

    _queue = dispatch_queue_create(NULL, DISPATCH_QUEUE_SERIAL);
    _suspended = NO;
    dispatch_set_target_queue(_queue, dispatch_get_main_queue());

    return self;
}

- (void)dealloc
{
    if (_suspended) {
        dispatch_resume(_queue);
    }
}

- (void)suspend
{
    if (self.suspended) {
        return;
    }

    self.suspended = YES;
    dispatch_suspend(self.queue);
}

- (void)resume
{
    if (!self.suspended) {
        return;
    }

    self.suspended = NO;
    dispatch_resume(self.queue);
}

- (void)enqueueBlock:(dispatch_block_t)block
{
    NSCParameterAssert(block != nil);

    if (!self.suspended) {
        block();
    } else {
        dispatch_async(self.queue, block);
    }
}

@end
