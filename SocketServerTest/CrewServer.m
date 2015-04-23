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
    
    // https://developer.apple.com/library/mac/documentation/CoreFoundation/Reference/CFSocketRef/index.html#//apple_ref/c/tdef/CFSocketCallBackType
    
    // https://developer.apple.com/library/ios/samplecode/SimpleNetworkStreams/Listings/ReceiveServerController_m.html#//apple_ref/doc/uid/DTS40008979-ReceiveServerController_m-DontLinkElementID_16
    
    myipv4cfsock = CFSocketCreate(kCFAllocatorDefault,
                                  PF_INET,
                                  SOCK_STREAM,
                                  IPPROTO_TCP,
                                  kCFSocketAcceptCallBack,    // kCFSocketDataCallBack
                                  (CFSocketCallBack)SocketCallBack,
                                  NULL);
    
    NSLog(@"CrewServer:init: myipv4cfsock\n%@", myipv4cfsock);
    NSLog(@"CFSocketIsValid %hhu", CFSocketIsValid(myipv4cfsock));
    
    // 1.1 Set Socket flags (reenable callback)
    
    CFOptionFlags sockopt = CFSocketGetSocketFlags (myipv4cfsock);
//    sockopt |= kCFSocketAutomaticallyReenableReadCallBack;

    /* Clear the close-on-invalidate flag. */
    sockopt &= ~kCFSocketCloseOnInvalidate;
    
    CFSocketSetSocketFlags(myipv4cfsock, sockopt);
    
    // 2. Bind socket to address
    
    struct sockaddr_in sin;
    
    memset(&sin, 0, sizeof(sin));
    sin.sin_len = sizeof(sin);
    sin.sin_family = AF_INET;
    sin.sin_port = htons(8084);
    sin.sin_addr.s_addr= INADDR_ANY;
    
    CFDataRef sincfd = CFDataCreate(
                                    kCFAllocatorDefault,
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
    CFRelease(socketsource);
}

/*
 *  Respond to incoming service requests
 */
void SocketCallBack(CFSocketRef socket,
                    CFSocketCallBackType type,
                    CFDataRef address,
                    const void *data,
                    void *info) {
    
    switch (type) {
            
        case kCFSocketAcceptCallBack:
            NSLog(@"kCFSocketAcceptCallBack");
            
            CFReadStreamRef readStream = NULL;
            CFWriteStreamRef writeStream = NULL;

            CFIndex bytes;
            UInt8 buffer[128];
            UInt8 recv_len = 0, send_len = 0;
            
            /* The native socket, used for various operations */
            CFSocketNativeHandle sock = *(CFSocketNativeHandle *) data;
            
            /* Create the read and write streams for the socket */
            CFStreamCreatePairWithSocket(kCFAllocatorDefault, sock,
                                         &readStream, &writeStream);
            
            if (!readStream || !writeStream) {
                close(sock);
                return;
            }
            
            CFReadStreamOpen(readStream);
            CFWriteStreamOpen(writeStream);
            
            memset(buffer, 0, sizeof(buffer));
            while (!strchr((char *) buffer, '\n') && recv_len < sizeof(buffer)) {
                bytes = CFReadStreamRead(readStream, buffer + recv_len,
                                         sizeof(buffer) - recv_len);
                if (bytes < 0) {
                    NSLog(@"CFReadStreamRead() failed: %ld", bytes);
                    close(sock);
                    return;
                }
                recv_len += bytes;
            }
            
            break;
            
        case kCFSocketConnectCallBack:
            NSLog(@"kCFSocketConnectCallBack");
            break;
            
        case kCFSocketDataCallBack:
            NSLog(@"kCFSocketDataCallBack");
            
            /*
             * Incoming data will be read in chunks in the background and the callback 
             * is called with the data argument being a CFData object containing the read data.
             */
            
            
            // Ref: http://collinbstuart.github.io/lessons/2013/01/01/CFSocket/
//            UInt8 *buffer = (UInt8 *)CFDataGetBytePtr((CFDataRef)data);
//            CFIndex length = CFDataGetLength((CFDataRef)data);
//            CFStringRef message = CFStringCreateWithBytes(kCFAllocatorDefault, buffer, length, kCFStringEncodingUTF8, TRUE);
//            
//            NSLog(@"message = %@", message);
            
            // NOTE: 'address' is the remote caller
            // http://stackoverflow.com/questions/3064582/how-to-use-cfnetwork-to-get-byte-array-from-sockets
            
            CFDataRef dataRef = (CFDataRef) data;
            NSLog(@"message = %@", dataRef);
            
            break;
        
        case kCFSocketNoCallBack:
            NSLog(@"kCFSocketNoCallBack");
            break;
            
        case kCFSocketReadCallBack:
            NSLog(@"kCFSocketReadCallBack");
            break;
            
        case kCFSocketWriteCallBack:
            NSLog(@"kCFSocketWriteCallBack");
            break;
            
        default:
            NSLog(@"Unknown type");
            break;
    }
    
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
