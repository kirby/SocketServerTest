//
//  CrewServer.m
//  SocketServerTest
//
//  Created by Shabaga, Kirby C on 4/22/15.
//  Copyright (c) 2015 Shabaga, Kirby C. All rights reserved.
//

#import "CrewServer.h"

@implementation CrewServer

{
    NSInputStream *inputStream;
    NSOutputStream *outputStream;
}

- (id)init {
    
    self = [super init];
    if (self) {
        
        SocketTest();
        
//        [self testStream];
        
    }
    
    return self;
}

void SocketTest() {
    
    // 1. Create socket object
    CFSocketRef myipv4cfsock;
    
    /*
     kCFSocketReadCallBack | kCFSocketAcceptCallBack | kCFSocketDataCallBack | kCFSocketConnectCallBack | kCFSocketWriteCallBack
     */
    
    //        CFSocketContext socketCtxt = {0, self, NULL, NULL, NULL};
//    CFSocketContext socketCtxt = {0, (__bridge void *)(this), NULL, NULL, NULL};
    
    myipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                                  PF_INET,
                                  SOCK_STREAM,
                                  IPPROTO_TCP,
//                                  kCFSocketDataCallBack,
                                    kCFSocketReadCallBack | kCFSocketAcceptCallBack | kCFSocketDataCallBack | kCFSocketConnectCallBack | kCFSocketWriteCallBack,
                                  (CFSocketCallBack)SocketCallBack,
                                  NULL);
    
    NSLog(@"CrewServer:init: myipv4cfsock\n%@", myipv4cfsock);
    NSLog(@"CFSocketIsValid %hhu", CFSocketIsValid(myipv4cfsock));
    
    // 2. Bind socket to address
    
    struct sockaddr_in sin;
    
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET; /* Address family */
    //        sin.sin_port = htons(0); /* Or a specific port */
    sin.sin_port = htons(8084);
    sin.sin_addr.s_addr= INADDR_ANY;    // do I need to put my address in here?
    
    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,    // may be NULL
                                    (UInt8 *)&sin,
                                    sizeof(sin));
    
    if (sincfd == NULL) {
        NSLog(@"Problem creating sincfd :-(");
    }
    
    CFSocketError socketError = CFSocketSetAddress(myipv4cfsock, sincfd);
    
    switch(socketError) {
        case kCFSocketSuccess:
            NSLog(@"kCFSocketSuccess");
            break;
            
        case kCFSocketError:
            NSLog(@"kCFSocketError");
            break;
            
        case kCFSocketTimeout:
            NSLog(@"kCFSocketTimeout");
            break;
            
        default:
            NSLog(@"Unknown socket error");
    }
    
    // 3. Add to runloop
    
    CFRunLoopSourceRef socketsource = CFSocketCreateRunLoopSource(
                                                                  kCFAllocatorDefault,
                                                                  myipv4cfsock,
                                                                  0);

    CFRunLoopAddSource(
                       CFRunLoopGetCurrent(),   // CFRunLoopGetMain
                       socketsource,
                       kCFRunLoopDefaultMode);

    
}

void SocketCallBack(CFSocketRef socket,
                    CFSocketCallBackType type,
                    CFDataRef address,
                    const void *data,
                    void *info) {
    
    NSLog(@"SocketCallBack");
    
}

-(void)start {
    NSLog(@"CrewServer:start");
}

-(void)stop {
    NSLog(@"CrewServer:stop");
}

-(void)testStream {
    
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)@"192.168.1.125", 8084, &readStream, &writeStream);
    inputStream = (__bridge NSInputStream *)readStream;
    outputStream = (__bridge NSOutputStream *)writeStream;
    
    [inputStream setDelegate:self];
    [outputStream setDelegate:self];
    
    [inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    [inputStream open];
    [outputStream open];

}

-(void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)eventCode {

    switch (eventCode) {
            
        case NSStreamEventOpenCompleted:
            NSLog(@"NSStreamEventOpenCompleted");
            break;
            
        case NSStreamEventHasBytesAvailable:
            
            if (theStream == inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([inputStream hasBytesAvailable]) {
                    len = [inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
            
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"Can not connect to the host!");
            break;
            
        case NSStreamEventEndEncountered:
            
            NSLog(@"NSStreamEventEndEncountered");

            [theStream close];
            [theStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            
            NSLog(@"NSStreamEventHasSpaceAvailable");
            
            [self sendMessageToNetCat];
            break;
            
        case NSStreamEventNone:
            
            NSLog(@"NSStreamEventNone");
            break;
            
        default:
            NSLog(@"Unknown event");
    }

}

-(void)sendMessageToNetCat {
    NSString *response  = [NSString stringWithFormat:@"Sent from iOS"];
    NSData *data = [[NSData alloc] initWithData:[response dataUsingEncoding:NSASCIIStringEncoding]];
    [outputStream write:[data bytes] maxLength:[data length]];
}

@end
