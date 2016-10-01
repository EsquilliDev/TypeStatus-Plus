#import "HBTSNotification.h"
#import "../typestatus-private/HBTSStatusBarAlertServer.h"

@implementation HBTSNotification

#pragma mark - NSObject

- (instancetype)init {
	self = [super init];

	if (self) {
		// set defaults for things that don’t have a nil default
		_boldRange = NSMakeRange(0, 0);
		_date = [NSDate date];
	}

	return self;
}

- (instancetype)initWithType:(HBTSNotificationType)type sender:(NSString *)sender iconName:(NSString *)iconName {
	self = [self init];

	if (self) {
		_content = [%c(HBTSStatusBarAlertServer) textForType:(HBTSStatusBarType)type sender:sender boldRange:&_boldRange];
		_statusBarIconName = iconName;
	}

	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];

	if (self) {
		// deserialise the easy stuff
		_sourceBundleID = [dictionary[kHBTSPlusAppIdentifierKey] copy];
		_content = [dictionary[kHBTSPlusMessageContentKey] copy];
		_statusBarIconName = [dictionary[kHBTSPlusMessageIconNameKey] copy];

		if (dictionary[kHBTSPlusDateKey]) {
			id date = dictionary[kHBTSPlusDateKey];

			// the date will be serialized to an NSNumber if it’s sent in an IPC
			// message
			if ([date isKindOfClass:NSNumber.class]) {
				_date = [NSDate dateWithTimeIntervalSince1970:((NSNumber *)date).doubleValue];
			} else if ([date isKindOfClass:NSDate.class]) {
				_date = [date copy];
			}
		}

		if (![dictionary[kHBTSPlusActionURLKey] isEqualToString:@""]) {
			_actionURL = [NSURL URLWithString:dictionary[kHBTSPlusActionURLKey]];
		}

		// deserialize the bold range to an NSRange
		NSArray <NSNumber *> *boldRangeArray = dictionary[kHBTSMessageBoldRangeKey];
		_boldRange = NSMakeRange(boldRangeArray[0].unsignedIntegerValue, boldRangeArray[1].unsignedIntegerValue);
	}

	return self;
}

#pragma mark - Serialization

- (NSString *)_contentWithBoldRange:(out NSRange *)boldRange {
	// we should never end up with nothing to return. crash if so
	NSAssert(_content, @"No notification content found");
	NSAssert(_content.length > 0, @"No notification content found");

	// grab the bold range, and return the content
	*boldRange = _boldRange;
	return _content;
}

- (NSDictionary *)dictionaryRepresentation {
	// grab the content and bold range
	NSRange boldRange = NSMakeRange(0, 0);
	NSString *content = [self _contentWithBoldRange:&boldRange];

	NSParameterAssert(_sourceBundleID);
	NSParameterAssert(_date);

	// return serialized dictionary
	return @{
		kHBTSPlusAppIdentifierKey: _sourceBundleID,
		kHBTSPlusMessageContentKey: content,
		kHBTSMessageBoldRangeKey: @[ @(boldRange.location), @(boldRange.length) ],
		kHBTSPlusMessageIconNameKey: _statusBarIconName ?: @"",
		kHBTSPlusDateKey: @(_date.timeIntervalSince1970),
		kHBTSPlusActionURLKey: _actionURL ? _actionURL.absoluteString : @""
	};
}

@end
