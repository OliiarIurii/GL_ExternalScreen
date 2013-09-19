//
//  ViewController.m
//  GL_ExternalScreen
//
//  Created by Iurii Oliiar on 9/13/13.
//  Copyright (c) 2013 Iurii Oliiar. All rights reserved.
//

#import "ViewController.h"
#import "ExternalViewController.h"

@interface ViewController ()<NSNetServiceBrowserDelegate, NSNetServiceDelegate>

@property (nonatomic, copy) NSDictionary *netServices;
@property (nonatomic, retain) NSNetServiceBrowser *browser;
@property (nonatomic, retain) UIWindow *externalWindow;

@end

@implementation ViewController

@synthesize netServices;
@synthesize browser;
@synthesize externalWindow;

- (id)init {
    self = [super init];
    if (self) {
        self.netServices = [NSDictionary dictionary];
        self.browser = [[[NSNetServiceBrowser alloc] init] autorelease];
        browser.delegate = self;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [browser searchForServicesOfType:@"_services._dns-sd._udp." inDomain:@""];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(externalScreenDidConnected:)
                                                 name:UIScreenDidConnectNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(externalScreenDidDisconnected:)
                                                 name:UIScreenDidDisconnectNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [browser stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIScreenDidDisconnectNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIScreenDidConnectNotification
                                                  object:nil];
}

#pragma mark NSNetServiceBrowser delegate methods

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSArray *types = [netServices allKeys];
    if (![types containsObject:aNetService.type]) {
        NSMutableDictionary *dict = [netServices mutableCopy] ;
        [dict setObject:[NSArray arrayWithObject:aNetService] forKey:aNetService.type];
        netServices = [dict copy];
        [dict release];
    } else {
        NSMutableArray *array = [[netServices objectForKey:aNetService.type] mutableCopy];
        [array addObject:aNetService];
        NSMutableDictionary *dict = [netServices mutableCopy];
        [dict setObject:[[array copy] autorelease] forKey:aNetService.type];
        self.netServices =  dict;
        [array release];
        [dict release];
    }
    [self.tableView reloadData];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing{
    NSArray *domains = [netServices allKeys];
    if ([domains containsObject:domainString]) {
        NSMutableDictionary *dict = [netServices mutableCopy] ;
        [dict removeObjectForKey:domainString];
        netServices = [dict copy];
        [dict release];
        [self.tableView reloadData];
    }
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didRemoveService:(NSNetService *)aNetService moreComing:(BOOL)moreComing {
    NSMutableDictionary *dict = [netServices mutableCopy];
    NSMutableArray *array = [[netServices objectForKey:aNetService.type] mutableCopy];
    
    if ([array count] > 1) {
        [array removeObject:aNetService];
        [dict setObject:[[array copy] autorelease] forKey:aNetService.type];
    } else {
        [dict removeObjectForKey:aNetService.type];
    }
    
    self.netServices =  dict;
    [array release];
    [dict release];
    [self.tableView reloadData];
    
}

#pragma mark UITableView methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSArray *types = [netServices allKeys];
    NSString *type = [types objectAtIndex:section];
    return [NSString stringWithFormat:@"Type %@", type];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[netServices allKeys] count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *types = [netServices allKeys];
    NSString *type = [types objectAtIndex:section];
    NSArray *services = [netServices objectForKey:type];
    return [services count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier] autorelease];
    }
   
    NSNetService *service = [self getServeiceByIndexPath:indexPath];
    cell.textLabel.text = service.name;
    cell.detailTextLabel.text = service.type;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[UIScreen screens] count] == 1) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Cannot find external screen"
                                                       delegate:nil
                                              cancelButtonTitle: @"Ok"
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
        return;
    }
 
    UIScreen *secondScreen = [[UIScreen screens] lastObject];
    CGRect screenBounds = secondScreen.bounds;
    ExternalViewController *vc = [[[ExternalViewController alloc] initWithFrame:screenBounds] autorelease];
    
    vc.service = [self getServeiceByIndexPath:indexPath];
    if (externalWindow == nil) {
        self.externalWindow = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
        self.externalWindow.screen = secondScreen;
    }
    vc.service = [self getServeiceByIndexPath:indexPath];
    externalWindow.rootViewController = vc;
    externalWindow.hidden = NO;
}

- (void) externalScreenDidDisconnected: (NSNotification *) notification {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                    message:@"Screen was disconnected"
                                                   delegate:nil
                                          cancelButtonTitle: @"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

- (void) externalScreenDidConnected: (NSNotification *) notification {
    UIScreen *secondScreen = [[UIScreen screens] lastObject];
    CGRect screenBounds = secondScreen.bounds;
    self.externalWindow = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
    self.externalWindow.screen = secondScreen;
}

#pragma mark helper method

- (NSNetService *)getServeiceByIndexPath:(NSIndexPath *)indexPath {
    NSArray *types = [netServices allKeys];
    NSString *type = [types objectAtIndex:indexPath.section];
    NSArray *services = [netServices objectForKey:type];
    NSNetService *result = [services objectAtIndex:indexPath.row];
    return result;
}

@end
