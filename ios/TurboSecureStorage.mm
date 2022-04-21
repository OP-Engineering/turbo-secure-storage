#import "TurboSecureStorage.h"
#import <TurboSecureStorage/TurboSecureStorage.h>
#import <React/RCTLog.h>
#import <Security/Security.h>
#import <jsi/jsi.h>
#import <iostream>

@interface TurboSecureStorage() <NativeTurboSecureStorageSpec>
@end

@implementation TurboSecureStorage

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params
{
    return std::make_shared<facebook::react::NativeTurboSecureStorageSpecJSI>(params);
}

+ (NSString *)moduleName
{
    return @"TurboSecureStorage";
}

- (NSMutableDictionary *)newDefaultDictionary:(NSString *)key {
    NSMutableDictionary* queryDictionary = [[NSMutableDictionary alloc] init];
    [queryDictionary setObject:(id)kSecClassGenericPassword forKey:(id)kSecClass];
    NSData *encodedIdentifier = [key dataUsingEncoding:NSUTF8StringEncoding];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrGeneric];
    [queryDictionary setObject:encodedIdentifier forKey:(id)kSecAttrAccount];
    [queryDictionary setObject:[[NSBundle mainBundle] bundleIdentifier] forKey:(id)kSecAttrService];
    
    return queryDictionary;
}

- (CFStringRef)getAccessibilityValue:(NSString *)accessibility
{
    NSDictionary *keyMap = @{
        @"AccessibleWhenUnlocked": (__bridge NSString *)kSecAttrAccessibleWhenUnlocked,
        @"AccessibleAfterFirstUnlock": (__bridge NSString *)kSecAttrAccessibleAfterFirstUnlock,
        @"AccessibleAlways": (__bridge NSString *)kSecAttrAccessibleAlways,
        @"AccessibleWhenPasscodeSetThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
        @"AccessibleWhenUnlockedThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        @"AccessibleAfterFirstUnlockThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        @"AccessibleAlwaysThisDeviceOnly": (__bridge NSString *)kSecAttrAccessibleAlwaysThisDeviceOnly
    };
    
    NSString *result = keyMap[accessibility];
    
    if (result) {
        return (__bridge CFStringRef)result;
    }
    
    return kSecAttrAccessibleAfterFirstUnlock;
}

- (NSDictionary *)setItem:(NSString *)key value:(NSString *)value options:(JS::NativeTurboSecureStorage::SpecSetItemOptions &)options {
    
    CFStringRef accessibility = kSecAttrAccessibleAfterFirstUnlock;
    
    if(&options == NULL) {
        RCTLogInfo(@"[turbo-secure-storage] options NOT passed");
    } else {
        accessibility = [self getAccessibilityValue:options.accessibility()];
    }
    
    // Delete item first
    [self deleteItem:key];
    
    NSMutableDictionary *dict = [self newDefaultDictionary:key];
    
    NSData* valueData = [value dataUsingEncoding:NSUTF8StringEncoding];
    [dict setObject:valueData forKey:(id)kSecValueData];
    [dict setObject:(__bridge id)accessibility forKey:(id)kSecAttrAccessible];
    
    OSStatus status = SecItemAdd((CFDictionaryRef)dict, NULL);
    
    if (status == noErr) {
        return @{};
    }

    return @{
        @"error": @"Could not save value",
    };
}

- (NSDictionary *)getItem:(NSString *)key {
    NSMutableDictionary *dict = [self newDefaultDictionary:key];
    
    [dict setObject:(id)kSecMatchLimitOne forKey:(id)kSecMatchLimit];
    [dict setObject:(id)kCFBooleanTrue forKey:(id)kSecReturnData];
    
    CFDataRef dataResult = nil;
    OSStatus status = SecItemCopyMatching((CFDictionaryRef)dict, (CFTypeRef*) &dataResult);
    
    if (status == noErr) {
        NSData* result = (__bridge NSData*) dataResult;
        NSString* returnString = [[NSString alloc] initWithData:result encoding:NSUTF8StringEncoding];
        
        return @{
            @"value": returnString
        };
    }
    
    return @{
        @"error": @"Could not get value"
    };
}

- (NSDictionary *)deleteItem:(NSString *)key {
    NSMutableDictionary *dict = [self newDefaultDictionary:key];
    
    OSStatus status = SecItemDelete((CFDictionaryRef)dict);
    
    if (status == noErr ) {
        return @{};
    }
    
    return @{
        @"error": @"Could delete value"
    };
}

@end
