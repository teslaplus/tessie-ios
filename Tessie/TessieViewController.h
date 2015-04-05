//
//  RBLViewController.h
//  Tessie
//
//  Created by tesla plus on 03/28/2015.
//  Copyright (c) 2015 Tesla Plus.  All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BLE.h"
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OEAcousticModel.h>
#import <OpenEars/OEEventsObserver.h>
#import <Slt/Slt.h>
#import <OpenEars/OEFliteController.h>

@interface TessieViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, BLEDelegate, OEEventsObserverDelegate>
{
    BLE *bleShield;
    UIActivityIndicatorView *activityIndicator;
}

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet UITextField *text;
@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;
@property (strong, nonatomic) OEFliteController *fliteController;
@property (strong, nonatomic) Slt *slt;

@end
