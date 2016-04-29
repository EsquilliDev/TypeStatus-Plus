#import "HBTSPlusPreferences.h"
#import "HBTSPlusBulletinProvider.h"
#import "HBTSPlusServer.h"
#import "HBTSPlusStateHelper.h"
#import "HBTSPlusTapToOpenController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <BulletinBoard/BBLocalDataProviderStore.h>
#import <Foundation/NSDistributedNotificationCenter.h>
#import <libstatusbar/LSStatusBarItem.h>
#import <libstatusbar/UIStatusBarCustomItem.h>
#import <libstatusbar/UIStatusBarCustomItemView.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplication.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBApplicationController.h>
#import <SpringBoard/SBLockScreenManager.h>
#import <UIKit/UIStatusBarItemView.h>
#import <version.h>

LSStatusBarItem *unreadCountStatusBarItem;

extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

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

	if (![[%c(HBTSPlusPreferences) sharedInstance] enabled]) {
		return;
	}

	// is libstatusbar loaded? if not, let's try dlopening it
	if (!%c(LSStatusBarItem)) {
		dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);
	}

	// still not loaded? probably not installed. just bail out
	if (!%c(LSStatusBarItem)) {
		return;
	}

	unreadCountStatusBarItem = [[%c(LSStatusBarItem) alloc] initWithIdentifier:@"ws.hbang.typestatusplus.unreadcount" alignment:StatusBarAlignmentRight];
	unreadCountStatusBarItem.imageName = @"TypeStatusPlusUnreadCount";
	unreadCountStatusBarItem.visible = YES;
}

%end

%hook SBApplication

- (void)setBadge:(id)arg1 {

	if ([[%c(HBTSPlusPreferences) sharedInstance] enabled] && [self.bundleIdentifier isEqualToString:[[%c(HBTSPlusPreferences) sharedInstance] applicationUsingUnreadCount]]) {
		[unreadCountStatusBarItem update];
	}
	%orig;
}

%end

#pragma mark - Constructor

%ctor {
	[HBTSPlusServer sharedInstance];
	[HBTSPlusTapToOpenController sharedInstance];

	[[NSDistributedNotificationCenter defaultCenter] addObserverForName:HBTSClientSetStatusBarNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		if (!((HBTSPlusPreferences *)[%c(HBTSPlusPreferences) sharedInstance]).enabled) {
			return;
		}

		NSString *content = notification.userInfo[kHBTSMessageContentKey];

		// right off the bat, if there's no title or content, stop right there.
		if (!content || [content isEqualToString:@""]) {
			return;
		}

		// if the user wants vibration, let’s do that
		if ([HBTSPlusStateHelper shouldVibrate]) {
			AudioServicesPlaySystemSoundWithVibration(4095, nil, @{
				@"VibePattern": @[ @YES, @(50) ],
				@"Intensity": @1
			});
		}

		// if the user wants a banner, let’s do that too
		if ([HBTSPlusStateHelper shouldShowBanner]) {
			// this is a hax, probably shouldn't be doing it... ¯\_(ツ)_/¯
			NSString *appIdentifier = ((HBTSPlusTapToOpenController *)[%c(HBTSPlusTapToOpenController) sharedInstance]).appIdentifier ?: @"com.apple.MobileSMS";

			// make sure this is a messages notification
			if ([appIdentifier isEqualToString:@"com.apple.MobileSMS"]) {
				// pass it over to the bulletin provider to do its thing
				[[HBTSPlusBulletinProvider sharedInstance] showMessagesBulletinWithContent:content];
			}
		}
	}];

	%init;
}
