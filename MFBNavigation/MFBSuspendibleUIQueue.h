#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 Enqueues blocks on the main dispatch queue and implements suspend/resume
 semantics.

 It's primary use is to queue view controller presentation calls.
 The nature of those operations implies unbalanced suspend/resume calls,
 hence class tracks suspension state internally.

 This class is not thread safe and is only intended to be used from the main
 queue.
 */
@interface MFBSuspendibleUIQueue : NSObject

- (void)resume;
- (void)suspend;
- (void)enqueueBlock:(dispatch_block_t)block;

@end

NS_ASSUME_NONNULL_END
