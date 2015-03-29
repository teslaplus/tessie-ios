//
//  RBLCellTableViewCell.h
//  Tessie
//
//  Created by tesla plus on 03/28/2015.
//  Copyright (c) 2015 Tesla Plus.  All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TessieCommandTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *send;
@property (weak, nonatomic) IBOutlet UIImageView *receive;
@property (weak, nonatomic) IBOutlet UILabel *text;

@end
