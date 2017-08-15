//
//  AFFSearchDisplay.h
//  AnyfishApp
//
//  Created by Bob Lee on 15/9/17.
//  Copyright (c) 2015年 Anyfish. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AFFSearchDisplayDelegate;

/**
 * 使用说明
 * UISearchBar不使用系统Display时使用。
   1.实现背景毛玻璃效果，需要原来的vc配合控制。
   2.默认显示时的提示内容需要原来vc提供。
   3.内部已经对导航栏、没有查询导数据做了关联处理。
   4.原来vc需要指定相关委托
   具体使用参考鱼信主界面
 */
@class AFFViewController;

@interface AFFSearchDisplay : UIImageView <UIScrollViewDelegate>

@property (nonatomic, readonly, nullable) UISearchBar                 *searchBar;    ///< 查询
@property (nonatomic, readonly, nullable) UIViewController           *viewController;
@property (nonatomic, assign, nullable)   id<AFFSearchDisplayDelegate> delegate;
@property (nonatomic, assign) BOOL isSearching;    ///< 是否查询中
@property (nonatomic, readonly, nullable) UITableView *searchResultsTableView;    ///< will return non-nil. create if requested
@property (nonatomic, assign) BOOL isHideWhenCellSelected;    ///< 是否cell点击后隐藏查询栏，默认YES
@property (nonatomic, assign) BOOL isShortLook;    ///< 是否显示字母查询默认 = NO
@property (nonatomic, strong) NSString *btnSearchTitle;    ///< 有输入内容时按钮标题；默认是取消
@property (nonatomic, strong) NSString *placeHolder;    ///< 搜索提示；默认是“搜索”
@property (nonatomic) UIReturnKeyType returnKeyType;                       // default is UIReturnKeySearch (See note under UIReturnKeyType enum)

@property (nonatomic, assign) BOOL              showEmptyView;      ///< 是否在没有数据时显示（UIScrollView）提示，默认为YES
@property (nonatomic, assign) BOOL isSearchWhenInputChanged;    ///< 是否输入关键字变化自动搜索，默认YES；否则点击确定才搜索，外部自己控制isSearching体现加载效果

- (id)initWithSearchBar:(UISearchBar*)searchBar viewController:(UIViewController*)viewController;

- (void)cleanSelf;

@end

@protocol AFFSearchDisplayDelegate <NSObject>

@optional

- (void)displayWillShow:(AFFSearchDisplay*)display searchBar:(UISearchBar*)searchBar;
- (void)displayWillHide:(AFFSearchDisplay*)display searchBar:(UISearchBar*)searchBar;

/**
 * 获取自定义支持的字母序列，否则显示所有26个字母
 */
- (NSArray*)displayWithShortLookKey;

/**
 * 当查询栏目的显示数据需要支持选择时，要实现此方法控制查询栏目的操作按钮，获取显示的数据源
    注意：数据必须为AFFData 子类时有效，且仅关心基类的isSelected属性
 */
- (NSArray*)displayDataSource:(UITableView*)tableView;

/**
 * 查询输入变化
 */
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText;

/**
 * 异步block查询
 * @param  searchBar  查询控件
 * @param  searchText  输入查询条件
 
 * @return success=YES 查询成功，刷新列表；success=NO 查询失败，显示errorDesc
 */
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText block:(void(^)(BOOL success, NSString *errorDesc))block;

/**
 * 有字母查询是要实现这个方法
 * @param  searchBar  查询控件
 * @param  searchText  查询输入内容
 * @param  shortLook  字母快速锁定
 
 * @return
 */
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText shortLook:(NSString*)shortLook;


/**
 * 搜索栏目按钮点击；可根据searchBar是否有输入文本判断是取消，还是确认
 * @param  searchBar  查询控件
 * @param  btn  按钮
 
 * @return
 */
- (void)searchBarBtnClicked:(UISearchBar*)searchBar btn:(UIButton*)btn;

- (void)searchBarCancelBtnClicked:(UISearchBar*)searchBar btn:(UIButton*)btn;

/**
 * 异步block查询
 * @param  searchBar  查询控件
 * @param  searchText  输入查询条件
 * @param  shortLook  字母快速锁定
 
 * @return success=YES 查询成功，刷新列表；success=NO 查询失败，显示errorDesc
 */
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText shortLook:(NSString*)shortLook block:(void(^)(BOOL success, NSString *errorDesc))block;;

// Variable height support

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section;
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section;

// Section header & footer information. Views are preferred over title should you decide to provide both

- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section;   // custom view for header. will be adjusted to default or specified header height
- (nullable UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section;   // custom view for footer. will be adjusted to default or specified footer height

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0);

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView;              // Default is 1 if not implemented
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark 空数据时
- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView;
- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView;
- (UIView*)customViewForEmptyDataSet:(UIScrollView *)scrollView;
- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView;
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView;
//- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView;
- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView;
- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView;
- (void)emptyDataSetDidTapView:(UIScrollView *)scrollView;
- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView;

@end
