#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/ps/IOPowerSources.h>

@interface CDVOSXBattery : CDVPlugin
{
    CFRunLoopSourceRef runLoopSource;
    float level;
    bool isPlugged;
    NSString *callbackId;
}

@property(nonatomic) CFRunLoopSourceRef runLoopSource;
@property(nonatomic) float level;
@property(nonatomic) bool isPlugged;
@property(strong) NSString *callbackId;

- (void)start:(CDVInvokedUrlCommand *)command;
- (void)stop:(CDVInvokedUrlCommand *)command;
- (NSDictionary *)getBatteryStatus;
- (void)dealloc;

void handlePowerSourceChange(CDVOSXBattery *context);

@end
