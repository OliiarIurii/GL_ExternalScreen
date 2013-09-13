//
//  ExternalViewController.h
//  GL_ExternalScreen
//
//  Created by Iurii Oliiar on 9/13/13.
//  Copyright (c) 2013 Iurii Oliiar. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExternalViewController : UIViewController

@property (nonatomic, retain) NSNetService *service;

- (id)initWithFrame:(CGRect)frame_;

@end
