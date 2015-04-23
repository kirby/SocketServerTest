//
//  CrewServer.h
//  SocketServerTest
//
//  Created by Shabaga, Kirby C on 4/22/15.
//  Copyright (c) 2015 Shabaga, Kirby C. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CoreFoundation/CoreFoundation.h>
#include <sys/socket.h>
#include <netinet/in.h>

@interface CrewServer : NSObject <NSStreamDelegate>

-(id)init;
-(void)start;
-(void)stop;
-(void)testStream;
-(void)sendMessageToNetCat;

@end
