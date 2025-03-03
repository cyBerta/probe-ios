#import <Foundation/Foundation.h>

@interface SettingsUtility : NSObject

+ (NSArray*)getSettingsCategories;
+ (NSArray*)getSettingsForCategory:(NSString*)categoryName;
+ (NSString*)getTypeForSetting:(NSString*)setting;

+ (NSArray*)getAutomaticTestsEnabled;
+ (NSArray*)addRemoveAutomaticTest:(NSString*)testName;

+ (NSString*)getVerbosity;

+ (NSArray*)getSitesCategories;

+ (NSArray*)getSitesCategoriesDisabled;
+ (NSArray*)getSitesCategoriesEnabled;
+ (NSArray*)addRemoveSitesCategory:(NSString*)categoryName;
+ (long)getNumberCategoriesEnabled;

+ (NSArray*)getSettingsForTest:(NSString*)testName :(BOOL)includeAll;

+ (BOOL)getSettingWithName:(NSString*)settingName;

+ (BOOL)isSendCrashEnabled;

+ (BOOL)isNotificationEnabled;

+ (NSString*)getOrGenerateUUID4;

+ (void)incrementAppOpenCount;

+ (NSInteger)getAppOpenCount;

+ (void)registeredForNotifications;
@end
