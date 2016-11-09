#import "HBTSPlusPreferences.h"
#import "HBTSPlusAlertController.h"
#import "HBTSPlusBulletinProvider.h"
#import "HBTSPlusServer.h"
#import "HBTSPlusStateHelper.h"
#import "HBTSPlusTapToOpenController.h"
#import "../api/HBTSNotification.h"
#import <AudioToolbox/AudioToolbox.h>
#import <BulletinBoard/BBLocalDataProviderStore.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <libstatusbar/LSStatusBarItem.h>
#import <libstatusbar/UIStatusBarCustomItem.h>
#import <libstatusbar/UIStatusBarCustomItemView.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <UIKit/UIStatusBarItemView.h>
#import <version.h>

HBTSPlusPreferences *preferences;
LSStatusBarItem *unreadCountStatusBarItem;

extern void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

#pragma mark - Notification Center

%hook BBLocalDataProviderStore

- (void)loadAllDataProvidersAndPerformMigration:(BOOL)performMigration {
	%orig;
	[self addDataProvider:[HBTSPlusBulletinProvider sharedInstance] performMigration:NO];
}

%end

#pragma mark - Unread Count

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
	%orig;

	if (!((HBTSPlusPreferences *)[%c(HBTSPlusPreferences) sharedInstance]).enabled) {
		return;
	}

	// try loading libstatusbar
	dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);

	// hmm not loaded? probably not installed. just bail out
	if (!%c(LSStatusBarItem)) {
		return;
	}

	unreadCountStatusBarItem = [[%c(LSStatusBarItem) alloc] initWithIdentifier:@"ws.hbang.typestatusplus.unreadcount" alignment:StatusBarAlignmentRight];
	unreadCountStatusBarItem.imageName = @"TypeStatusPlusUnreadCount";
	unreadCountStatusBarItem.visible = YES;
}

%end

%hook SBApplication

- (void)setBadge:(id)badge {
	%orig;

	if ([preferences.unreadCountApps containsObject:self.bundleIdentifier]) {
		[unreadCountStatusBarItem update];
	}
}

%end

#pragma mark - Relay hook

%hook HBTSSpringBoardServer

- (void)receivedRelayedNotification:(NSDictionary *)userInfo {
	%orig;
	[[NSDistributedNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:HBTSPlusReceiveRelayNotification object:nil userInfo:userInfo]];
}

%end

#pragma mark - Test notification

void TestNotification() {
	HBTSNotification *notification = [[HBTSNotification alloc] initWithType:HBTSMessageTypeTyping sender:@"Johnny Appleseed" iconName:@"TypeStatus"];
	notification.sourceBundleID = @"com.apple.MobileSMS";
	[HBTSPlusAlertController sendNotification:notification];
}

#pragma mark - Constructor

%ctor {
	// make sure typestatus free and plus client are loaded before we do anything
	dlopen("/Library/MobileSubstrate/DynamicLibraries/TypeStatus.dylib", RTLD_LAZY);
	dlopen("/Library/MobileSubstrate/DynamicLibraries/TypeStatusPlusClient.dylib", RTLD_LAZY);

	// initialise our singleton classes
	[HBTSPlusServer sharedInstance];
	[HBTSPlusTapToOpenController sharedInstance];

	preferences = [%c(HBTSPlusPreferences) sharedInstance];

	// when preferences update, forcefully update the status bar item
	[preferences registerPreferenceChangeBlock:^{
		[unreadCountStatusBarItem update];
	}];

	// register for test notification notification
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)TestNotification, CFSTR("ws.hbang.typestatusplus/TestNotification"), NULL, kNilOptions);

	// when a set status bar notification is sent by typestatus free
	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:HBTSClientSetStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *nsNotification) {
		// not enabled? don’t do anything
		if (!preferences.enabled) {
			return;
		}

		// get the notification type
		HBTSMessageType type = ((NSNumber *)nsNotification.userInfo[kHBTSMessageTypeKey]).unsignedIntegerValue;

		// if it’s an ended notification, just clear all bulletins and return
		if (type == HBTSMessageTypeTypingEnded && !preferences.keepAllBulletins) {
			[[HBTSPlusBulletinProvider sharedInstance] clearAllBulletins];
			return;
		}

		HBTSNotification *notification = [[HBTSNotification alloc] initWithDictionary:nsNotification.userInfo];

		// right off the bat, if there’s no title or content, stop right there.
		if (!notification.content || [notification.content isEqualToString:@""]) {
			return;
		}

		// if the user wants vibration, let’s do that
		if ([HBTSPlusStateHelper shouldVibrate]) {
			// TODO: document and define constants for these things
			AudioServicesPlaySystemSoundWithVibration(4095, nil, @{
				@"VibePattern": @[ @YES, @(50) ],
				@"Intensity": @1
			});
		}

		// if the user wants a banner, let’s do that too. else if they want an
		// undim, do that (SBUIUnlockOptionsTurnOnScreenFirstKey doesn’t actually do
		// an unlock… weird stuff)
		if ([HBTSPlusStateHelper shouldShowBanner]) {
			[[HBTSPlusBulletinProvider sharedInstance] showBulletinForNotification:notification];
		} else if (preferences.wakeWhenLocked) {
			[[%c(SBLockScreenManager) sharedInstance] unlockUIFromSource:0 withOptions:@{
				@"SBUIUnlockOptionsTurnOnScreenFirstKey": @YES,
				@"SBUIUnlockOptionsStartFadeInAnimation": @YES
			}];
		}
	}];

	%init;
}
