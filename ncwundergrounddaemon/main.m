#import <notify.h>

#import "AMMNCWundergroundDaemonManager.h"

int main(int argc, char **argv, char **envp) {

    @autoreleasepool {
        NSLog(@"Launched.");

        AMMNCWundergroundDaemonManager *manager = [[AMMNCWundergroundDaemonManager alloc] init];

        int notifyToken, status;
        status = notify_register_dispatch("com.amm.ncwunderground.location_should_update",
                                            &notifyToken,
                                            dispatch_get_main_queue(), ^(int t) {
                                                NSLog(@"Received request to update location.");
                                                [manager getLocation];
                                            });
        NSTimer *keepRunningTimer = [[NSTimer alloc] initWithFireDate:[NSDate distantFuture]
                                                             interval:1000
                                                               target:manager
                                                             selector:@selector(keepRunning:)
                                                             userInfo:nil
                                                              repeats:YES];

        [[NSRunLoop currentRunLoop] addTimer:keepRunningTimer
                                     forMode:NSRunLoopCommonModes];

        // Execute run loop
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];

        NSLog(@"Exiting.");
    }

    return 0;
}
