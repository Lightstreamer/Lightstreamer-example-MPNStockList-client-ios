//
//  StockListCell.h
//  StockList Demo for iOS
//
// Copyright 2013 Weswit Srl
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
// http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <UIKit/UIKit.h>


@interface StockListCell : UITableViewCell {
	IBOutlet UILabel *_nameLabel;
	IBOutlet UILabel *_lastLabel;
	IBOutlet UILabel *_timeLabel;
	IBOutlet UIImageView *_dirImage;
	IBOutlet UILabel *_changeLabel;
	IBOutlet UILabel *_bidLabel;
	IBOutlet UILabel *_askLabel;
	IBOutlet UILabel *_minLabel;
	IBOutlet UILabel *_maxLabel;
	IBOutlet UILabel *_refLabel;
	IBOutlet UILabel *_openLabel;
}


#pragma mark -
#pragma mark Properties

@property (nonatomic, readonly) UILabel *nameLabel;
@property (nonatomic, readonly) UILabel *lastLabel;
@property (nonatomic, readonly) UILabel *timeLabel;
@property (nonatomic, readonly) UIImageView *dirImage;
@property (nonatomic, readonly) UILabel *changeLabel;
@property (nonatomic, readonly) UILabel *bidLabel;
@property (nonatomic, readonly) UILabel *askLabel;
@property (nonatomic, readonly) UILabel *minLabel;
@property (nonatomic, readonly) UILabel *maxLabel;
@property (nonatomic, readonly) UILabel *refLabel;
@property (nonatomic, readonly) UILabel *openLabel;


@end
