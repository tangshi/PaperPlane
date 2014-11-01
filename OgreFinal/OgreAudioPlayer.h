//
//  OgreAudioPlayer.h
//  OgreFinal
//
//  Created by 唐 仕 on 13-10-20.
//
//

#import <AVFoundation/AVFoundation.h>

@interface OgreAudioPlayer : AVAudioPlayer

- (id)initWithContentsOfURL:(NSURL *)url error:(NSError **)outError;

@end
