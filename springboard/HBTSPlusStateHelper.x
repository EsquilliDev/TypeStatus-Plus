#import "HBTSPlusStateHelper.h"
#import "HBTSPlusPreferences.h"
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBLockScreenManager.h>

@implementation HBTSPlusStateHelper

+ (BOOL)shouldShowBanner {
	HBTSPlusPreferences *preferences = [%c(HBTSPlusPreferences) sharedInstance];

	SBLockScreenManager *lockScreenManager = [%c(SBLockScreenManager) sharedInstance];
	BOOL onLockScreen = lockScreenManager.isUILocked;

	SpringBoard *app = (SpringBoard *)[UIApplication sharedApplication];
	NSString *frontmostAppIdentifier = app._accessibilityFrontMostApplication.bundleIdentifier;

	// TODO: wow this is impossible to read
	BOOL shouldShowBanner = ([preferences showBannersOnLockScreen] && onLockScreen) || ([preferences showBannersOnHomeScreen] && !frontmostAppIdentifier && !onLockScreen) || ([preferences showBannersInApps] && frontmostAppIdentifier);
	return shouldShowBanner;
}

+ (BOOL)shouldVibrate {
	// TODO: this is pretty much the same as above with just one thing changed?
	HBTSPlusPreferences *preferences = [%c(HBTSPlusPreferences) sharedInstance];

	SBLockScreenManager *lockScreenManager = [%c(SBLockScreenManager) sharedInstance];
	BOOL onLockScreen = lockScreenManager.isUILocked;

	SpringBoard *app = (SpringBoard *)[UIApplication sharedApplication];
	NSString *frontmostAppIdentifier = app._accessibilityFrontMostApplication.bundleIdentifier;

	BOOL shouldVibrate =  ([preferences vibrateOnLockScreen] && onLockScreen) || ([preferences vibrateOnHomeScreen] && !frontmostAppIdentifier && !onLockScreen) || ([preferences vibrateInApps] && frontmostAppIdentifier);

	return shouldVibrate;
}

@end
