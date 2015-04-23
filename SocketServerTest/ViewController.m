//
//  ViewController.m
//  SocketServerTest
//
//  Created by Shabaga, Kirby C on 4/22/15.
//  Copyright (c) 2015 Shabaga, Kirby C. All rights reserved.
//

#import "ViewController.h"
#import "CrewServer.h"

@interface ViewController ()

@end

@implementation ViewController
{
    CrewServer *crewServer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    crewServer = [[CrewServer alloc] init];
//    [crewServer testStream];
}
- (IBAction)sendMessageToNetcat:(id)sender {
    NSLog(@"sendMessageToNetcat");
//    [crewServer sendMessageToNetCat];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
