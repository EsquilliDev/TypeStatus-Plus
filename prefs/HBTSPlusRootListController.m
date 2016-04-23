#include "HBTSPlusRootListController.h"
#import <CepheiPrefs/HBAppearanceSettings.h>
#import <CepheiPrefs/HBSupportController.h>
#import <UIKit/UIImage+Private.h>

@implementation HBTSPlusRootListController

#pragma mark - HBListController

+ (NSString *)hb_shareText {
	return @"I couldn’t be more happy I joined the exclusive TypeStatus Plus beta group. You can join, too!";
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"https://typestatus.com/plus"];
}

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

#pragma mark - PSListController

- (void)viewDidLoad {
	[super viewDidLoad];

	HBAppearanceSettings *appearance = [[HBAppearanceSettings alloc] init];
	appearance.tintColor = [UIColor colorWithRed:0.094 green:0.412 blue:0.325 alpha:1.00];
	appearance.navigationBarTintColor = [UIColor colorWithRed:0.055 green:0.055 blue:0.055 alpha:1.00];
	appearance.invertedNavigationBar = YES;
	appearance.translucentNavigationBar = NO;
	appearance.tableViewCellTextColor = [UIColor whiteColor];
	appearance.tableViewCellBackgroundColor = [UIColor colorWithRed:0.055 green:0.055 blue:0.055 alpha:1.00];
	appearance.tableViewCellSeparatorColor = [UIColor colorWithRed:0.120 green:0.120 blue:0.120 alpha:1.00];
	appearance.tableViewCellSelectionColor = [UIColor colorWithRed:0.149 green:0.149 blue:0.149 alpha:1.00];
	appearance.tableViewBackgroundColor = [UIColor colorWithRed:0.089 green:0.089 blue:0.089 alpha:1.00];
	self.hb_appearanceSettings = appearance;

	UIImage *headerLogo = [UIImage imageNamed:@"headerlogo" inBundle:[NSBundle bundleForClass:self.class]];
	self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:headerLogo] autorelease];
	self.navigationItem.titleView.alpha = 0.0;

	[self performSelector:@selector(animateIconAlpha) withObject:nil afterDelay:0.5];
}

#pragma mark - Callbacks

- (void)animateIconAlpha {
	[UIView animateWithDuration:0.5 animations:^{
		self.navigationItem.titleView.alpha = 1;
	} completion:nil];
}

- (void)showSupportEmailController {
	UIViewController *viewController = (UIViewController *)[HBSupportController supportViewControllerForBundle:[NSBundle bundleForClass:self.class] preferencesIdentifier:@"ws.hbang.typestatusplus"];
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
