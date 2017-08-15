//
//  AFFSearchDisplay.m
//  AnyfishApp
//
//  Created by Bob Lee on 15/9/17.
//  Copyright (c) 2015年 Anyfish. All rights reserved.
//

#import "AFFSearchDisplay.h"
#import "UIImage+Blur.h"
#import "UIImage+FX.h"
#import "AFFData.h"

#define  offsetY 44+20

static NSString *emptyTbvResue = @"emptyTbvResue";

static NSArray *arrShortLook;

@interface AFFSearchDisplay() <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate> {
    NSMutableArray *mArrShortLook;
    NSInteger shortIndex;
    int    selCount;
    CGRect frameTF, frameCancel;
}

@property (nonatomic, strong)   UIButton    *cancelBtn;                 ///< 取消按钮
@property (nonatomic, weak)     UITextField *searchTxtF;    ///< 输入栏
@property (nonatomic, strong) UIView *viewSearching;    ///< 查询中效果
@property (nonatomic, strong) UIActivityIndicatorView *activity;    ///< 异步加载效果

@end

@implementation AFFSearchDisplay

- (id)initWithSearchBar:(UISearchBar *)searchBar viewController:(UIViewController *)viewController {
    CGRect frame = viewController.view.bounds;
    frame.origin.y += offsetY;
    frame.size.height -= offsetY;
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        self.hidden = YES;
        self.isHideWhenCellSelected = YES;
        _isSearchWhenInputChanged = YES;
        self.returnKeyType = UIReturnKeySearch;
        
        _searchBar = searchBar;
        _searchBar.delegate = self;
        _viewController = viewController;
        
        self.placeHolder = @"搜索";
        
        _searchResultsTableView = [[UITableView alloc] initWithFrame:self.bounds style:UITableViewStylePlain];
        _searchResultsTableView.autoresizesSubviews = YES;
        _searchResultsTableView.delaysContentTouches = NO;
        _searchResultsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _searchResultsTableView.backgroundColor = [UIColor clearColor];
        _searchResultsTableView.dataSource = self;
        _searchResultsTableView.delegate = self;
        
        [self addSubview:_searchResultsTableView];
        
        CALayer *topLine = [[CALayer alloc] init];
        topLine.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), 0.25);
        [self.layer addSublayer:topLine];
        
        _showEmptyView = YES;
        [_viewController.view addSubview:self];
        shortIndex = -1;
    }
    
    if(arrShortLook==nil){
        arrShortLook = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G",
                         @"H", @"I", @"J", @"K", @"L", @"M", @"N",
                         @"O", @"P", @"Q", @"R", @"S", @"T", @"U",
                         @"V", @"W", @"X", @"Y", @"Z", @"#",
                         ];
    }
    
    return self;
}

- (void)setHidden:(BOOL)hidden {
    if(super.hidden == hidden)
        return;
    
    // 这2句放在前面，不然修改不了输入框宽度，系统处理办法应该是动态相对计算了的
    [self.searchBar setShowsCancelButton:!hidden animated:YES];
    self.cancelBtn.hidden = hidden;
    
    // 这里可见时需要获取ViewController.view作为毛玻璃效果
    if(!hidden){
        if(self.delegate && [self.delegate respondsToSelector:@selector(displayWillShow:searchBar:)]){
            [self.delegate displayWillShow:self searchBar:self.searchBar];
        }
        
        // 控制下层scroll不能滑动
        UIView *superV = _searchBar.superview;
        while (superV && ![superV isKindOfClass:[UIScrollView class]]) {
            superV = superV.superview;
        }
        
        if([superV isKindOfClass:[UIScrollView class]]){
            ((UIScrollView*)superV).scrollEnabled = NO;
        }
        
        // 如果是首页需要控制下导航不显示
        if(_viewController == _viewController.navigationController.viewControllers.firstObject){
            _viewController.tabBarController.tabBar.hidden = YES;
        }
        
        if(self.delegate && [self.delegate respondsToSelector:@selector(searchBar:textDidChange:shortLook:)]){
            [self.delegate searchBar:_searchBar textDidChange:nil shortLook:nil];
        }else if(self.delegate && [self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]){
            [self.delegate searchBar:_searchBar textDidChange:nil];
        }else if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:block:)]) {
            [self.delegate searchBar:_searchBar textDidChange:nil block:^(BOOL success, NSString *errorDesc) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.isSearching){
                        self.isSearching = NO;
                        
                        if(success){
                            [_searchResultsTableView reloadData];
                        }
                    }
                });
            }];
        }else if ([self.delegate respondsToSelector:@selector(searchBar:textDidChange:shortLook:block:)]) {
            [self.delegate searchBar:_searchBar textDidChange:nil shortLook:nil block:^(BOOL success, NSString *errorDesc) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(self.isSearching){
                        self.isSearching = NO;
                        
                        if(success){
                            [_searchResultsTableView reloadData];
                        }
                    }
                });
            }];
        }
        [_searchResultsTableView reloadData];
        
        _searchResultsTableView.hidden = YES;
        self.alpha = 0;
        selCount = 0;
        [self updateRightItem];
        
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             UIImage *img = [AFFSearchDisplay imageWithScreenShoot];
                             CGRect frame = CGRectMake(0, offsetY, img.size.width, CGRectGetHeight(self.bounds));
                             img = [img imageCroppedToRect:frame];
                             img = [img blurredImageWithRadius:40.0];
                             self.image = img;
                             self.alpha = 1;
                             _searchResultsTableView.hidden = NO;
                         } completion:nil];
        
    }else {
        if(self.delegate && [self.delegate respondsToSelector:@selector(displayWillHide:searchBar:)]){
            [self.delegate displayWillHide:self searchBar:self.searchBar];
        }
        
        [_searchBar resignFirstResponder];
        _searchBar.text = nil;
        self.isSearching = NO;
        
        [self searchBar:_searchBar textDidChange:nil];
        self.image = nil;
        
        UIView *superV = _searchBar.superview;
        while (superV && ![superV isKindOfClass:[UIScrollView class]]) {
            superV = superV.superview;
        }
        
        if([superV isKindOfClass:[UIScrollView class]]){
            ((UIScrollView*)superV).scrollEnabled = YES;
        }
        
        // 如果是首页需要控制下导航不显示
        if(_viewController == _viewController.navigationController.viewControllers.firstObject){
            _viewController.tabBarController.tabBar.hidden = NO;
        }
    }
    
    
    [self.viewController.navigationController setNavigationBarHidden:!hidden animated:YES];
    [[UIApplication sharedApplication] setStatusBarStyle:hidden ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault animated:YES];
    
    self.userInteractionEnabled = !hidden;
    super.hidden = hidden;
}

+ (UIImage *)imageWithScreenShoot {
    CGSize imageSize = [UIScreen mainScreen].bounds.size;
    
    if (NULL != &UIGraphicsBeginImageContextWithOptions) {
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    } else {
        UIGraphicsBeginImageContext(imageSize);
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            CGContextSaveGState(context);
            
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            
            CGContextConcatCTM(context, [window transform]);
            
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            [[window layer] renderInContext:context];
            
            CGContextRestoreGState(context);
        }
    }
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.hidden = YES;
}

- (void)cancelSearch:(UIButton*)btn {
    if([self.delegate respondsToSelector:@selector(searchBarCancelBtnClicked:btn:)]){
        [self.delegate searchBarCancelBtnClicked:self.searchBar btn:btn];
        return;
    }
    
    if(![btn.titleLabel.text isEqualToString:@"取消"]){
        if([self.delegate respondsToSelector:@selector(searchBarBtnClicked:btn:)]){
            [self.delegate searchBarBtnClicked:self.searchBar btn:btn];
            return;
        }
    }
    
    self.hidden = YES;
}

- (void)cleanSelf {
    self.delegate = nil;
    [self removeFromSuperview];
    self.searchBar.delegate = nil;
    self.searchResultsTableView.dataSource = nil;
    self.searchResultsTableView.delegate = nil;
    [self.searchResultsTableView removeFromSuperview];
}

- (void)btnClicked:(UIButton*)btn {
    UIButton *btnOld = [self.searchResultsTableView.tableHeaderView viewWithTag:shortIndex+1000];
    btnOld.selected = NO;
    
    shortIndex = btn.tag-1000;
    btn.selected = !btn.selected;
    
    // 触发筛选
    [self searchBar:self.searchBar textDidChange:self.searchBar.text];
}

- (void)setIsShortLook:(BOOL)isShortLook {
    _isShortLook = isShortLook;
    
    //    if(_isShortLook){
    //        self.searchResultsTableView.tableHeaderView = [self tableViewHeader];
    //    }
}

- (void)updateRightItem {
    if([self.delegate respondsToSelector:@selector(displayDataSource:)]){
        int count = 0;
        NSArray *mArr = [self.delegate displayDataSource:_searchResultsTableView];
        if(mArr.count>0 && [mArr[0] isKindOfClass:[AFFData class]]){
            for(AFFData *data in mArr){
                if(data.isSelected){
                    count ++;
                }
            }
        }
        
        if(self.cancelBtn && (count!=selCount || (count==0 && selCount==0 && ![self.cancelBtn.titleLabel.text isEqualToString:@"取消"]))){
            selCount = count;
            [self updateRightItemTitle:count>0 ? [NSString stringWithFormat:@"%@(%d)",@"确定", count]: @"取消"];
        }
    }else {
        [self updateRightItemTitle:@"取消"];
    }
}

- (void)updateRightItemTitle:(NSString*)title {
    if(self.cancelBtn){
        [self.cancelBtn setTitle:title forState:UIControlStateNormal];
        
        CGFloat width = 40;
        width = MAX(CGRectGetWidth(frameCancel), width);
        
        CGFloat delta = CGRectGetWidth(frameCancel)-width;
        CGRect frame = frameTF;
        frame.size.width += delta;
        self.searchTxtF.frame = frame;
        
        frame = frameCancel;
        frame.origin.x += delta;
        frame.size.width = width;
        self.cancelBtn.frame = frame;
    }
}

- (void)setIsSearching:(BOOL)isSearching {
    _isSearching = isSearching;
    
    if(isSearching){
        if(self.activity){
            self.activity.hidden = NO;
        }else {
            
            CGRect frame = self.searchTxtF.frame;
            UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.activity = activity;
            
            CGFloat width = 22;
            frame.origin.x = CGRectGetWidth(frame)-5-width*2;
            frame.origin.y = (CGRectGetHeight(frame)-width)/2;
            frame.size = CGSizeMake(width, width);
            
            activity.frame = frame;
            [self.searchTxtF addSubview:activity];
        }
        
        [self.activity startAnimating];
    }else {
        if(self.activity){
            [self.activity stopAnimating];
            self.activity.hidden = YES;
        }
    }
}

- (void)setPlaceHolder:(NSString *)placeHolder {
    _placeHolder = placeHolder;
    self.searchBar.placeholder = placeHolder;
}

- (void)setReturnKeyType:(UIReturnKeyType)returnKeyType {
    if(returnKeyType == _returnKeyType)
        return;
    
    _returnKeyType = returnKeyType;
    if(self.searchTxtF){
        self.searchTxtF.returnKeyType = returnKeyType;
    }
}

- (void)setIsSearchWhenInputChanged:(BOOL)isSearchWhenInputChanged {
    _isSearchWhenInputChanged = isSearchWhenInputChanged;
}

#pragma mark tableview 委托
- (UIView*)tableViewHeader {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = self.viewController.view.backgroundColor;
    
    NSArray *shortLook = nil;
    if(self.delegate && [self.delegate respondsToSelector:@selector(displayWithShortLookKey)]){
        shortLook = [self.delegate displayWithShortLookKey];
    }else {
        shortLook = arrShortLook;
    }
    
    if(shortLook.count>0)
        mArrShortLook = [NSMutableArray arrayWithArray:shortLook];
    
    CGFloat width = 45, height = 30, padding = 2.5;
    int columns = CGRectGetWidth(self.frame)/width;
    int rows = ceilf((CGFloat)shortLook.count/(CGFloat)columns);
    
    CGFloat x=0,y=5;
    for(NSInteger i=0; i<shortLook.count; i++){
        if(i%columns==0){
            x = (CGRectGetWidth(self.frame)-(width*columns))/2;
            if(i>0)
                y += height;
        }
        
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(x+padding, y+padding, width-padding*2, height-padding*2)];
        btn.layer.cornerRadius = 3;
        btn.layer.borderWidth = 0.5;
        btn.layer.borderColor = [UIColor blueColor].CGColor;
        btn.layer.masksToBounds = YES;
        [btn setBackgroundImage:[AFFSearchDisplay imageWithColor:[UIColor blueColor]] forState:UIControlStateSelected];
        [btn setTitle:[shortLook objectAtIndex:i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        btn.titleLabel.font = [UIFont systemFontOfSize:10];
        btn.tag = 1000+i;
        [btn addTarget:self action:@selector(btnClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:btn];
        
        x+=width;
    }
    
    CGFloat maxHeight = rows*height+5*2;
    view.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), maxHeight);
    return view;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if([self.delegate respondsToSelector:@selector(tableView:viewForHeaderInSection:)]){
        return [self.delegate tableView:tableView viewForHeaderInSection:section];
    }
    
    return nil;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if([self.delegate respondsToSelector:@selector(tableView:viewForFooterInSection:)]){
        return [self.delegate tableView:tableView viewForFooterInSection:section];
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if([self.delegate respondsToSelector:@selector(numberOfSectionsInTableView:)]){
        return [self.delegate numberOfSectionsInTableView:tableView];
    }
    
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    if([self.delegate respondsToSelector:@selector(tableView:heightForHeaderInSection:)]){
        return [self.delegate tableView:tableView heightForHeaderInSection:section];
    }
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if([self.delegate respondsToSelector:@selector(tableView:heightForFooterInSection:)]){
        return [self.delegate tableView:tableView heightForFooterInSection:section];
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([self.delegate respondsToSelector:@selector(tableView:numberOfRowsInSection:)]){
        return [self.delegate tableView:tableView numberOfRowsInSection:section];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //    [self updateRightItem];
    
    if([self.delegate respondsToSelector:@selector(tableView:cellForRowAtIndexPath:)]){
        return [self.delegate tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    return [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:emptyTbvResue];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([self.delegate respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)]){
        return [self.delegate tableView:tableView heightForRowAtIndexPath:indexPath];
    }
    
    return 44;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([self.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)]){
        [self.delegate tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
    
    if(self.isHideWhenCellSelected){
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
        [self.viewController.navigationController setNavigationBarHidden:NO animated:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
        self.hidden = YES;
    }else {
        [self updateRightItem];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([self.delegate respondsToSelector:@selector(tableView:didDeselectRowAtIndexPath:)]){
        [self.delegate tableView:tableView didDeselectRowAtIndexPath:indexPath];
    }
}

// 滑动是隐藏键盘
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.searchBar endEditing:YES];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (scrollView.contentOffset.y < -100) {
        self.hidden = YES;
    }
}

#pragma mark empty view

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(titleForEmptyDataSet:)]){
        return [self.delegate titleForEmptyDataSet:scrollView];
    }
    
    NSString *text = @"没有数据";
    UIFont *font = nil;
    UIColor *textColor = nil;
    
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    
    textColor = [UIColor blackColor];
    font = [UIFont systemFontOfSize:15];
    
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)descriptionForEmptyDataSet:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(descriptionForEmptyDataSet:)]){
        return [self.delegate descriptionForEmptyDataSet:scrollView];
    }
    
    return nil;
}

- (UIView*)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(customViewForEmptyDataSet:)]){
        return [self.delegate customViewForEmptyDataSet:scrollView];
    }
    
    return nil;
}

- (UIImage *)imageForEmptyDataSet:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(imageForEmptyDataSet:)]){
        return [self.delegate imageForEmptyDataSet:scrollView];
    }
    
    UIImage *img = [UIImage imageNamed:@"ic_error_no_data"];
    return img;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView {
    //    if([self.delegate respondsToSelector:@selector(verticalOffsetForEmptyDataSet:)]){
    //        return [self.delegate verticalOffsetForEmptyDataSet:scrollView];
    //    }
    
    return self.isShortLook ? -50 : -100.0;
}

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView {
    return self.showEmptyView;
}

- (BOOL)emptyDataSetShouldAllowTouch:(UIScrollView *)scrollView {
    //    if([self.delegate respondsToSelector:@selector(emptyDataSetShouldAllowTouch:)]){
    //        return [self.delegate emptyDataSetShouldAllowTouch:scrollView];
    //    }
    return YES;
}

- (BOOL)emptyDataSetShouldAllowScroll:(UIScrollView *)scrollView {
    //    if([self.delegate respondsToSelector:@selector(emptyDataSetShouldAllowScroll:)]){
    //       return [self.delegate emptyDataSetShouldAllowScroll:scrollView];
    //    }
    
    return YES;
}

- (void)emptyDataSetDidTapView:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(emptyDataSetDidTapView:)]){
        [self.delegate emptyDataSetDidTapView:scrollView];
    }
    
    self.hidden = YES;
}

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView {
    if([self.delegate respondsToSelector:@selector(emptyDataSetDidTapButton:)]){
        [self.delegate emptyDataSetDidTapButton:scrollView];
    }
}

#pragma mark - UISearchBarDelegate Methods

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    self.hidden = NO;
    
    return YES;
}

- (BOOL)searchBarShouldEndEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.isShortLook = self.isShortLook;
    
    if(self.placeHolder)
        self.searchTxtF.placeholder = self.placeHolder;
    
    if(self.cancelBtn) {
        return;
    }
    
    UIView *cancelButton = nil;
    
    // 这里考虑修改查询输入框的字体
    for (UIView *searchbuttons in [searchBar subviews]){
        if ([searchbuttons isKindOfClass:[UIButton class]] && cancelButton==nil) {
            cancelButton = searchbuttons;
            break;
        }else{
            for(UIView *sub in [searchbuttons subviews]){
                if ([sub isKindOfClass:[UIButton class]] && cancelButton==nil) {
                    cancelButton = sub;
                }else if([sub isKindOfClass:[UITextField class]]){
                    UITextField *txtf = (UITextField*)sub;
                    txtf.font = [UIFont systemFontOfSize:14];
                    txtf.textColor = [UIColor blackColor];
                    if(self.placeHolder)
                        txtf.placeholder = self.placeHolder;
                    self.searchTxtF = txtf;
                    txtf.returnKeyType = self.returnKeyType;
                    
                    CGRect frame1 = self.searchTxtF.frame;
                    frameTF = frame1;
                }
            }
        }
    }
    
    if(cancelButton){
        UIButton *temp = (UIButton*)cancelButton;
        temp.titleLabel.text = nil;
        temp.hidden = YES;
        
        CGRect frame = cancelButton.frame;
        frame.origin.y += 2;
        frameCancel = frame;
        
        self.cancelBtn = [[UIButton alloc] initWithFrame:frame];
        self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:13];
        [self.cancelBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [self.cancelBtn addTarget:self action:@selector(cancelSearch:) forControlEvents:UIControlEventTouchUpInside];
        [[searchBar subviews][0] addSubview:self.cancelBtn];
        
        [self updateRightItem];
    }
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    self.searchResultsTableView.tableHeaderView = nil;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.hidden = YES;
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    if([self.delegate respondsToSelector:@selector(searchBarBtnClicked:btn:)]){
        [self.delegate searchBarBtnClicked:searchBar btn:nil];
    }
    
    [searchBar endEditing:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(!self.isSearchWhenInputChanged){
        return;
    }
    
    if(self.delegate==nil && searchBar){
        return;
    }
    
    if(self.btnSearchTitle && !self.cancelBtn.isHidden){
        [self updateRightItemTitle:searchText==nil?@"取消":self.btnSearchTitle];
    }
    
    // 异步优先
    if(self.isShortLook){
        NSString *look = [mArrShortLook objectAtIndex:shortIndex];
        if(look==[mArrShortLook lastObject]){
            look = nil;
        }
        
        if([self.delegate respondsToSelector:@selector(searchBar:textDidChange:shortLook:block:)]){
            self.isSearching = searchText || look;
            [self.delegate searchBar:searchBar textDidChange:searchText shortLook:look block:^(BOOL success, NSString *errorDesc) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSearching = NO;
                    
                    if(success){
                        [_searchResultsTableView reloadData];
                    }
                });
            }];
        }else if([self.delegate respondsToSelector:@selector(searchBar:textDidChange:shortLook:)]){
            NSString *look = [mArrShortLook objectAtIndex:shortIndex];
            if(look==[mArrShortLook lastObject]){
                look = nil;
            }
            
            [self.delegate searchBar:searchBar textDidChange:searchText shortLook:look];
            [_searchResultsTableView reloadData];
        }
    }else {
        if([self.delegate respondsToSelector:@selector(searchBar:textDidChange:block:)]){
            self.isSearching = searchText.length>0;
            [self.delegate searchBar:searchBar textDidChange:searchText block:^(BOOL success, NSString *errorDesc) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.isSearching = NO;
                    
                    if(success){
                        [_searchResultsTableView reloadData];
                    }
                });
            }];
        }else if([self.delegate respondsToSelector:@selector(searchBar:textDidChange:)]){
            [self.delegate searchBar:searchBar textDidChange:searchText];
            [_searchResultsTableView reloadData];
        }
    }
}

+ (UIImage *)imageWithColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end
