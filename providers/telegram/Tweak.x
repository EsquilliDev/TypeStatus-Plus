#import <TypeStatusProvider/HBTSProvider.h>
#import <TypeStatusProvider/HBTSProviderController.h>

@interface TLUpdate : NSObject

@end

@interface TLUpdate$updateUserTyping : TLUpdate

@property (nonatomic) NSInteger user_id;

@end

@interface TLUpdates$updateShort : NSObject

@property(retain, nonatomic) TLUpdate *update;

@end

@interface TGTelegraphUserInfoController : NSObject

- (instancetype)initWithUid:(NSInteger)uid;

@end

@interface TGUser : NSObject

- (NSString *)displayName;

@end

@interface TLUpdates$updates : TLUpdate

@property (retain, nonatomic) NSArray *chats;

@property (retain, nonatomic) NSArray *users;

@property (retain, nonatomic) NSArray *updates;

@end

@interface TLPeer : NSObject

@end

@interface TLUpdate$updateReadHistoryOutbox : TLUpdate

@property(retain, nonatomic) TLPeer *peer;

@end

@interface TLPeer$peerUser : TLPeer

@property (nonatomic) NSInteger user_id;

@end

%hook TGTLSerialization

- (id)parseMessage:(NSData *)message {
	id original = %orig;

	HBTSProvider *telegramProvider = [[HBTSProviderController sharedInstance] providerForAppIdentifier:@"ph.telegra.Telegraph"];

	if ([original isKindOfClass:%c(TLUpdates$updateShort)]) {
		TLUpdates$updateShort *updateShort = (TLUpdates$updateShort *)original;
		if (![updateShort.update isKindOfClass:%c(TLUpdate$updateUserTyping)] && ![updateShort.update isKindOfClass:%c(TLUpdate$updateChatUserTyping)]) {
			return updateShort;
		}

		TLUpdate$updateUserTyping *userTypingUpdate = (TLUpdate$updateUserTyping *)updateShort.update;
		NSInteger userId = userTypingUpdate.user_id;

		TGTelegraphUserInfoController *userController = [[%c(TGTelegraphUserInfoController) alloc] initWithUid:userId];
		TGUser *user = [userController valueForKey:@"_user"];
		NSString *userDisplayName = [user displayName];

		HBTSNotification *notification = [[HBTSNotification alloc] initWithType:HBTSMessageTypeTyping sender:userDisplayName iconName:@"TypeStatusPlusTelegram"];
		[telegramProvider showNotification:notification];
	} else if ([original isKindOfClass:%c(TLUpdates$updates)]) {
		TLUpdates$updates *update = (TLUpdates$updates *)original;
		for (TLUpdate *regularUpdate in update.updates) {
			if ([regularUpdate isKindOfClass:%c(TLUpdate$updateReadHistoryOutbox)]) {
				TLUpdate$updateReadHistoryOutbox *readUpdate = (TLUpdate$updateReadHistoryOutbox *)regularUpdate;

				TLPeer$peerUser *peer = (TLPeer$peerUser *)readUpdate.peer;
				if (![peer isKindOfClass:%c(TLPeer$peerUser)]) {
					break;
				}

				NSInteger userId = peer.user_id;

				TGTelegraphUserInfoController *userController = [[%c(TGTelegraphUserInfoController) alloc] initWithUid:userId];
				TGUser *user = [userController valueForKey:@"_user"];
				NSString *userDisplayName = [user displayName];

				HBTSNotification *notification = [[HBTSNotification alloc] initWithType:HBTSMessageTypeReadReceipt sender:userDisplayName iconName:@"TypeStatusPlusTelegram"];
				[telegramProvider showNotification:notification];
			}
		}
	}

	return original;
}

%end

%ctor {
	if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"ph.telegra.Telegraph"]) {
		%init;
	}
}
