#import <TypeStatusPlusProvider/HBTSPlusProvider.h>
#import <TypeStatusPlusProvider/HBTSPlusProviderController.h>

#define XMPPConnectionChatStateDidChange @"XMPPConnectionChatStateDidChange"
#define ChatStorageDidUpdateChatSession @"ChatStorageDidUpdateChatSession"

@interface WAMessageInfo : NSObject

@property (nonatomic, retain) NSMutableArray *_typeStatusPlus_alreadyNotifiedReceipts;

@property (nonatomic, copy, readonly) NSDictionary *allReadReceipts;

@end

@interface WAMessage : NSObject

@property (nonatomic, retain) WAMessageInfo *messageInfo;

@end

@interface WAChatSession

@property (nonatomic, retain) WAMessage *lastMessage;

@end

@interface WAChatStorage

- (WAChatSession *)newOrExistingChatSessionForJID:(NSString *)jid;

@end

@interface WASharedAppData

+ (WAChatStorage *)chatStorage;

@end

@interface WAContactInfo

- (instancetype)initWithChatSession:(WAChatSession *)chatSession;

- (NSString *)fullName;

@end

%hook WAMessageInfo

%property (nonatomic, retain) NSMutableArray *_typeStatusPlus_alreadyNotifiedReceipts;

- (id)init {
	if ((self = %orig)) {
		self._typeStatusPlus_alreadyNotifiedReceipts = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc {
	[self._typeStatusPlus_alreadyNotifiedReceipts release];

	%orig;
}

%end

NSString *nameFromJID(NSString *jid) {
	WAChatStorage *storage = [%c(WASharedAppData) chatStorage];
	WAChatSession *chatSession = [storage newOrExistingChatSessionForJID:jid];
	WAContactInfo *contactInfo = [[%c(WAContactInfo) alloc] initWithChatSession:chatSession];
	return contactInfo.fullName;
}

%ctor {
	// for when someone reads a message

	[[NSNotificationCenter defaultCenter] addObserverForName:ChatStorageDidUpdateChatSession object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		WAChatSession *chatSession = notification.userInfo[@"ChatSession"];
		WAMessage *message = [chatSession lastMessage];
		WAMessageInfo *messageInfo = message.messageInfo;
		NSDictionary *allReadReceipts = messageInfo.allReadReceipts;

		for (NSString *jid in [allReadReceipts allKeys]) {
			// if we haven't already shown a notification for this read receipt, show one
			if (![messageInfo._typeStatusPlus_alreadyNotifiedReceipts containsObject:jid]) {
				[messageInfo._typeStatusPlus_alreadyNotifiedReceipts addObject:jid];
				NSString *name = nameFromJID(jid);

				HBTSPlusProvider *whatsAppProvider = [[HBTSPlusProviderController sharedInstance] providerWithAppIdentifier:@"net.whatsapp.WhatsApp"];
				[whatsAppProvider showNotificationWithIconName:@"TypeStatusPlusWhatsApp" title:@"Read:" content:name];
			}
		}
	}];

	// for when someone types a message

	[[NSNotificationCenter defaultCenter] addObserverForName:XMPPConnectionChatStateDidChange object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
		NSDictionary *userInfo = notification.userInfo;
		NSInteger state = ((NSNumber *)userInfo[@"State"]).integerValue;
		HBTSPlusProvider *whatsAppProvider = [[HBTSPlusProviderController sharedInstance] providerWithAppIdentifier:@"net.whatsapp.WhatsApp"];
		if (state == 1) {
			NSString *name = nameFromJID(userInfo[@"JID"]);
			[whatsAppProvider showNotificationWithIconName:@"TypeStatusPlusWhatsApp" title:@"Typing:" content:name];
		} else if (state == 0) {
			[whatsAppProvider hideNotification];
		}
	}];
}
