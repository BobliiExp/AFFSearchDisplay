//
//  ViewController.m
//  AFFSearchDisplay
//
//  Created by Bob Lee on 2017/8/15.
//  Copyright © 2017年 45YG. All rights reserved.
//

#import "ViewController.h"
#import "AFFSearchDisplay.h"
#import "AFFData.h"

@interface ViewController () <UITableViewDelegate, UITableViewDataSource, AFFSearchDisplayDelegate>


@property (nonatomic, strong) UISearchBar       *searchBar;                 ///< 查询框
@property (nonatomic, strong) AFFSearchDisplay  *searchDisp;                ///< 自定义展示查询界面控件
@property (nonatomic, weak)   UITableView       *tableView;

@property (nonatomic, strong) NSMutableArray *mArrData;
@property (nonatomic, strong) NSMutableArray *mArrSearch;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    [self setupData];
}

- (void)setup {
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44)];
    self.searchBar = searchBar;
    
    CGRect frame = self.view.bounds;
    UITableView *tabv = [[UITableView alloc] initWithFrame:frame style:UITableViewStylePlain];
    self.tableView = tabv;
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizesSubviews = YES;
    self.tableView.delaysContentTouches = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.contentOffset = CGPointMake(0, self.searchBar.frame.size.height);
    self.tableView.tableHeaderView = self.searchBar;
    
    self.searchDisp = [[AFFSearchDisplay alloc] initWithSearchBar:self.searchBar viewController:self];
    self.searchDisp.delegate = self;
    self.searchDisp.isHideWhenCellSelected = YES;
}

- (void)setupData {
    self.mArrData = [NSMutableArray array];
    self.mArrSearch = [NSMutableArray array];
    
    for(NSInteger i=0; i<10; i++){
        AFFData *data = [[AFFData alloc] init];
        data.title = [NSString stringWithFormat:@"title %ld", i];
        [self.mArrData addObject:data];
    }
}

#pragma mark tableview 委托

- (NSArray*)sourceArray:(NSIndexPath*)indexPath tbv:(UITableView*)tbv{
    NSArray *arr = nil;
    if(![tbv isEqual:self.tableView]){
        arr = self.mArrSearch;
    }else {
       arr = self.mArrData;
    }
    
    return arr;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *arr = [self sourceArray:[NSIndexPath indexPathForRow:0 inSection:section] tbv:tableView];
    return arr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
        NSArray *arr = [self sourceArray:indexPath tbv:tableView];
    AFFData *data = [arr objectAtIndex:indexPath.row];
    static NSString *cellId = @"cellID";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId];
    }
    
    cell.textLabel.text = data.title;
    cell.selected = data.isSelected;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText block:(void (^)(BOOL, NSString *))block {
    // 必须增加这个处理，不然异步工作线程反复进入查询会出问题，tbv刷新会挂掉
    if(searchText.length==0){
        [self.mArrSearch removeAllObjects];
        
        if(block)block(YES, nil);
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self.mArrSearch removeAllObjects];
        
        for(AFFData *data in weakSelf.mArrData){
            if([data.title containsString:searchText]) {
                [self.mArrSearch addObject:data];
            }
        }
        
        if(block)block(YES, nil);
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
