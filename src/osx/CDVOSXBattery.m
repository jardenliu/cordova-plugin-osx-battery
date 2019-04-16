
#import "CDVOSXBattery.h"
#import <IOKit/ps/IOPowerSources.h>

@interface CDVOSXBattery (PrivateMethods)
- (void)updateOnlineStatus;
    @end

@implementation CDVOSXBattery
    
@synthesize runLoopSource, level, callbackId, isPlugged;
    
- (void)start:(CDVInvokedUrlCommand*)command
    {
        self.callbackId = command.callbackId;
        
        handlePowerSourceChange(self);
        
        runLoopSource = (CFRunLoopSourceRef)IOPSNotificationCreateRunLoopSource((IOPowerSourceCallbackType)handlePowerSourceChange, (__bridge void *)(self));
        if(runLoopSource) {
            CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, kCFRunLoopDefaultMode);
        }
    }
    
    
-(NSDictionary *)getBatteryStatus
    {
        
        CFTypeRef blob = IOPSCopyPowerSourcesInfo();
        
        CFArrayRef sources = IOPSCopyPowerSourcesList(blob);
        
        CFDictionaryRef pSource = NULL;
        const void *psValue;
        
        int numOfSources = (int)CFArrayGetCount(sources);
        
        NSMutableDictionary* batteryData = [NSMutableDictionary dictionaryWithCapacity:2];
        
        // 计算剩余电量
        for (int i = 0 ; i < numOfSources ; i++)
        {
            pSource = IOPSGetPowerSourceDescription(blob, CFArrayGetValueAtIndex(sources, i));
            if (!pSource)
            {
                NSLog(@"Error in IOPSGetPowerSourceDescription");
                return batteryData;
            }
            psValue = (CFStringRef)CFDictionaryGetValue(pSource, CFSTR(kIOPSNameKey));
            
            int curCapacity = 0;
            int maxCapacity = 0;
            NSString *state = @"";
            bool isPlugged = FALSE;
            float percent;
            
            // 获取当前容量
            psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSCurrentCapacityKey));
            CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &curCapacity);
            
            // 获取最大容量
            psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSMaxCapacityKey));
            CFNumberGetValue((CFNumberRef)psValue, kCFNumberSInt32Type, &maxCapacity);
            
            // 计算百分比
            percent = ((float)curCapacity/(float)maxCapacity * 100.0f);
            
            psValue = CFDictionaryGetValue(pSource, CFSTR(kIOPSPowerSourceStateKey));
            state = (__bridge NSString *)((CFStringRef)psValue);
            
            isPlugged = [state containsString: @"AC Power"];
            
            [batteryData setObject:[NSNumber numberWithInteger:percent] forKey:@"level"];
            [batteryData setObject:[NSNumber numberWithBool:isPlugged] forKey:@"isPlugged"];
            
            return batteryData;
        }
        return batteryData;
    }
    
    
- (void)stop:(CDVInvokedUrlCommand*)command
    {
        if (self.callbackId) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[self getBatteryStatus]];
            [result setKeepCallbackAsBool:NO];
            [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
        }
        self.callbackId = nil;
        if(self.runLoopSource) {
            CFRunLoopSourceInvalidate(self.runLoopSource);
            CFRelease(self.runLoopSource);
        }

    }
    
- (void)pluginInitialize
    {
        self.level = -1.0;
    }
    
- (void)dealloc
    {
        [self stop:nil];
    }
    
- (void)onReset
    {
        [self stop:nil];
    }
    
- (void)updateBatteryStatus:(NSDictionary*)batteryData
    {
        if (self.callbackId) {
            CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:batteryData];
            [result setKeepCallbackAsBool:YES];
            [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
        }
    }
    
    void handlePowerSourceChange(CDVOSXBattery* context) {
        NSDictionary* batteryData = [context getBatteryStatus];
        [context updateBatteryStatus:batteryData];
    }
    
    @end
