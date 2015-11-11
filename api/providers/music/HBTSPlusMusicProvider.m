#import "HBTSPlusMusicProvider.h"
#import <Foundation/NSDistributedNotificationCenter.h>
#import <MediaRemote/MediaRemote.h>

@implementation HBTSPlusMusicProvider {
	NSString *_lastUsedSongName, *_lastUsedArtistName;
}

- (id)init {
	if (self = [super init]) {
		self.name = @"Music";
		self.preferencesBundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/TypeStatusPlusMusic.bundle/"];
		self.preferencesClass = @"HBTSPlusMusicProviderListController";

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(typeStatusPlusMusic_mediaInfoDidChange:) name:(NSString *)kMRMediaRemoteNowPlayingInfoDidChangeNotification object:nil];
	}
	return self;
}

- (void)typeStatusPlusMusic_mediaInfoDidChange:(NSNotification *)notification {
	MRMediaRemoteGetNowPlayingInfo(dispatch_get_main_queue(), ^(CFDictionaryRef result) {
		NSDictionary *dictionary = (__bridge NSDictionary *)result;
		NSString *songName = dictionary[(NSString *)kMRMediaRemoteNowPlayingInfoTitle];
		NSString *artistName = dictionary[(NSString *)kMRMediaRemoteNowPlayingInfoArtist];
		if (_lastUsedSongName && artistName && ![_lastUsedSongName isEqualToString:songName] && ![_lastUsedArtistName isEqualToString:artistName]) {
			_lastUsedSongName = songName;
			_lastUsedArtistName = artistName;
			[self showNotification:[NSString stringWithFormat:@"The song %@ by %@ is now playing!", songName, artistName]];
		}
	});

}

@end