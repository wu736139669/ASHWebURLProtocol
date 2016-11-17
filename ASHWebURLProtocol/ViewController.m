//
//  ViewController.m
//  ASHWebURLProtocol
//
//  Created by xmfish on 16/11/16.
//  Copyright © 2016年 ash. All rights reserved.
//

#import "ViewController.h"


@interface ViewController ()
@property(nonatomic,strong) UIWebView* webview;;
@end

@implementation ViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _webview = [[UIWebView alloc] init];
    _webview.frame = self.view.bounds;
    [self.view addSubview:_webview];
    
    [self loadWebView];
}

- (void)loadWebView
{
    NSURL *url = [NSURL URLWithString:@"http://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webview loadRequest:request];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
