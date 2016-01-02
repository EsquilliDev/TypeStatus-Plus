#include "HBTSPlusRootListController.h"
#import <UIKit/UIImage+Private.h>
#import <CepheiPrefs/HBSupportController.h>

@implementation HBTSPlusRootListController

+ (NSString *)hb_shareText {
	return @"I couldn't be more happy I joined the exclusive TypeStatus Plus beta group. You can join, too!";
}

+ (NSURL *)hb_shareURL {
	return [NSURL URLWithString:@"https://typestatus.com/plus"];
}

+ (NSString *)hb_specifierPlist {
	return @"Root";
}

+ (UIColor *)hb_tintColor {
	return [UIColor colorWithRed:0.094 green:0.412 blue:0.325 alpha:1.00];
}

+ (UIColor *)hb_navigationBarTintColor {
	return [UIColor colorWithRed:0.055 green:0.055 blue:0.055 alpha:1.00];
}

+ (BOOL)hb_invertedNavigationBar {
	return YES;
}

+ (BOOL)hb_translucentNavigationBar {
	return YES;
}

+ (UIColor *)hb_tableViewCellTextColor {
	return [UIColor whiteColor];
}

+ (UIColor *)hb_tableViewCellBackgroundColor {
	return [UIColor colorWithRed:0.055 green:0.055 blue:0.055 alpha:1.00];
}

+ (UIColor *)hb_tableViewCellSeparatorColor {
	return [UIColor colorWithRed:0.120 green:0.120 blue:0.120 alpha:1.00];
}

+ (UIColor *)hb_tableViewBackgroundColor {
	return [UIColor colorWithRed:0.089 green:0.089 blue:0.089 alpha:1.00];
}

- (void)viewDidLoad {
	[super viewDidLoad];

	UIImage *headerLogo = [UIImage imageNamed:@"headerlogo" inBundle:[NSBundle bundleForClass:self.class]];
	self.navigationItem.titleView = [[[UIImageView alloc] initWithImage:headerLogo] autorelease];
	self.navigationItem.titleView.alpha = 0.0;

	[self performSelector:@selector(animateIconAlpha) withObject:nil afterDelay:0.5];
}

- (void)animateIconAlpha {
	[UIView animateWithDuration:0.5 animations:^{
		self.navigationItem.titleView.alpha = 1;
	} completion:nil];
}

- (void)showSupportEmailController {
	UIViewController *viewController = (UIViewController *)[HBSupportController supportViewControllerForBundle:[NSBundle bundleForClass:self.class] preferencesIdentifier:@"com.tweakbattles.chrysalis"];
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
