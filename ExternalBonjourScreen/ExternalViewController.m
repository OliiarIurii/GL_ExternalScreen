//
//  ExternalViewController.m
//  GL_ExternalScreen
//
//  Created by Iurii Oliiar on 9/13/13.
//  Copyright (c) 2013 Iurii Oliiar. All rights reserved.
//

#import "ExternalViewController.h"

@interface ExternalViewController ()<NSNetServiceDelegate>

@property (nonatomic, assign) CGRect frame;
@property (nonatomic, retain) UITextView *textView;

@end

@implementation ExternalViewController

@synthesize frame;
@synthesize textView;
@synthesize service;

- (id)initWithFrame:(CGRect)frame_ {
    self = [super init];
    if (self != nil) {
        frame = frame_;
    }
    return self;
}

- (void)loadView {
    self.view = [[[UIView alloc] initWithFrame:frame] autorelease];
    self.textView = [[[UITextView alloc] initWithFrame:frame] autorelease];
    textView.editable = NO;
    textView.text = [NSString stringWithFormat:@"%@ %@ %@", service.type,service.domain,service.name];
    [self.view addSubview:textView];
}

- (void)setService:(NSNetService *)service_ {
    if (service != service_) {
        [service release];
        service = [service_ retain];
        service.delegate = self;
        self.textView.text = [NSString stringWithFormat:@"%@ %@ %@", service.type,service.domain,service.name];
    }
}

- (void)netServiceDidResolveAddress:(NSNetService *)sender {
    NSData *data = [sender TXTRecordData];
    if (data == nil) {
        return;
    }
    NSDictionary *txtDictionary = [NSNetService dictionaryFromTXTRecordData:data];
    NSMutableString *message = [NSMutableString stringWithFormat:@"Name %@ \n Type %@\n  Domain %@\n", service.name,
                                service.type,
                                service.domain];
    
    int count = [[txtDictionary allKeys] count];
    
    for (int k = 0; k < count; k++) {
        NSData *keyData = [[txtDictionary allKeys] objectAtIndex:k];
        NSString *key  = [[[NSString alloc] initWithData:keyData
                                               encoding:NSUTF8StringEncoding] autorelease];
        
        NSData *objectData = [txtDictionary objectForKey:keyData];
        NSString *object  = [[[NSString alloc] initWithData:objectData
                                               encoding:NSUTF8StringEncoding] autorelease];
        
        [message appendFormat:@"%@ %@ \n",key, object];
    }
    self.textView.text = [[message copy] autorelease];
}

@end
