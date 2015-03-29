//
//  RBLCellTableViewCell.m
//  Tessie
//
//  Created by tesla plus on 03/28/2015.
//  Copyright (c) 2015 Tesla Plus.  All rights reserved.
//

#import "TessieCommandTableViewCell.h"

@implementation TessieCommandTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
