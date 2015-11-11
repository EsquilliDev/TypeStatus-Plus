@class UIStatusBar;

@interface HBTSStatusBarAlertController : NSObject

+ (instancetype)sharedInstance;

- (void)addStatusBar:(UIStatusBar *)statusBar;
- (void)removeStatusBar:(UIStatusBar *)statusBar;

- (void)showWithIconName:(NSString *)iconName title:(NSString *)title content:(NSString *)content;
- (void)hide;

@end
