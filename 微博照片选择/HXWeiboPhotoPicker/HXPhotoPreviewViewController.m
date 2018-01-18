//
//  HXPhotoPreviewViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 17/2/9.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "HXPhotoPreviewViewController.h"
#import "HXPhotoPreviewViewCell.h"
#import "HXTransition.h"
#import "UIView+HXExtension.h"
#import "UIButton+HXExtension.h"
#import "HXPresentTransition.h"
#import "HXPhotoCustomNavigationBar.h"
@interface HXPhotoPreviewViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIViewControllerTransitioningDelegate>
@property (weak, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) UILabel *titleLb;
@property (strong, nonatomic) UIButton *rightBtn;
@property (strong, nonatomic) HXPhotoPreviewViewCell *livePhotoCell;
@property (assign, nonatomic) BOOL firstWillDisplayCell;
@property (strong, nonatomic) HXPhotoCustomNavigationBar *navBar;
@property (strong, nonatomic) UINavigationItem *navItem;
@property (assign, nonatomic) BOOL firstOn;
@end

@implementation HXPhotoPreviewViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.transitioningDelegate = self;
        self.modalPresentationStyle = UIModalPresentationCustom;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setup];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}
- (HXPhotoCustomNavigationBar *)navBar {
    if (!_navBar) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _navBar = [[HXPhotoCustomNavigationBar alloc] initWithFrame:CGRectMake(0, 0, width, kNavigationBarHeight)];
        _navBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [self.view addSubview:_navBar];
        [_navBar pushNavigationItem:self.navItem animated:NO];
        _navBar.tintColor = self.manager.UIManager.navLeftBtnTitleColor;
        if (self.manager.UIManager.navBackgroundImageName) {
            [_navBar setBackgroundImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.navBackgroundImageName] forBarMetrics:UIBarMetricsDefault];
        }else if (self.manager.UIManager.navBackgroundColor) {
            [_navBar setBackgroundColor:self.manager.UIManager.navBackgroundColor];
        }
    }
    return _navBar;
}
- (UINavigationItem *)navItem {
    if (!_navItem) {
        _navItem = [[UINavigationItem alloc] init];
        
        _navItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[NSBundle hx_localizedStringForKey:@"取消"] style:UIBarButtonItemStylePlain target:self action:@selector(dismissClick)];
        _navItem.titleView = self.titleLb;
    }
    return _navItem;
}
- (void)setup {
    if (self.isPreview) {
        // 防错,,,,,如果出现问题麻烦及时告诉我..... qq294005139
        for (HXPhotoModel *model in self.modelList) {
            model.selected = YES;
        }
    }
    
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat height = [UIScreen mainScreen].bounds.size.height;

    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.navItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.rightBtn];
    [self setupNavRightBtn];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.itemSize = CGSizeMake(width, height - kNavigationBarHeight);
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.minimumLineSpacing = 20;
    if (self.selectedComplete) {
        flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
    }else {
#ifdef __IPHONE_11_0
        if (@available(iOS 11.0, *)) {
#else
        if ((NO)) {
#endif
            flowLayout.sectionInset = UIEdgeInsetsMake(0, 10, 0, 10);
        }else {
            flowLayout.sectionInset = UIEdgeInsetsMake(-20, 10, 0, 10);
        }
    }
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(-10, kNavigationBarHeight, width + 20, height - kNavigationBarHeight) collectionViewLayout:flowLayout];
    collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    collectionView.backgroundColor = [UIColor whiteColor];
    collectionView.dataSource = self;
    collectionView.delegate = self;
    collectionView.pagingEnabled = YES;
    collectionView.showsVerticalScrollIndicator = NO;
    collectionView.showsHorizontalScrollIndicator = NO;
    collectionView.contentSize = CGSizeMake(self.modelList.count * (width + 20), 0);
    [collectionView registerClass:[HXPhotoPreviewViewCell class] forCellWithReuseIdentifier:@"cellId"];
    [self.view addSubview:collectionView];
    self.collectionView = collectionView;
#ifdef __IPHONE_11_0
    if (@available(iOS 11.0, *)) {
        self.collectionView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
#endif
    [collectionView setContentOffset:CGPointMake(self.index * (width + 20), 0) animated:NO];
    [self.view addSubview:self.selectedBtn];
    HXPhotoModel *model = self.modelList[self.index];
    self.selectedBtn.selected = model.selected;
    
    if (self.selectedComplete) {
        self.rightBtn.hidden = YES;
        self.selectedBtn.hidden = YES;
    }else {
        __weak typeof(self) weakSelf = self;
        [self.manager setPhotoLibraryDidChangeWithPhotoPreviewViewController:^(NSArray *collectionChanges){
            [weakSelf systemPhotoDidChange:collectionChanges];
        }];
    }
    [self.view addSubview:self.navBar];
    if (self.manager.UIManager.navBar) {
        self.manager.UIManager.navBar(self.navBar);
    }
    if (self.manager.UIManager.navItem) {
        self.manager.UIManager.navItem(self.navItem);
    }
    if (self.manager.UIManager.navRightBtn) {
        self.manager.UIManager.navRightBtn(self.rightBtn);
    }
}

- (void)setupNavRightBtn {
    if (self.manager.selectedList.count > 0) {
        self.navItem.rightBarButtonItem.enabled = YES;
        [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],(unsigned long)self.manager.selectedList.count] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.layer.borderWidth = 0;
        CGFloat rightBtnH = self.rightBtn.frame.size.height;
        CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
        self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
    }else {
        [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
        self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
        self.rightBtn.layer.borderWidth = 0;
    }
}
- (void)systemPhotoDidChange:(NSArray *)list {
    if (list.count > 0) {
        NSDictionary *dic = list.firstObject;
        PHFetchResultChangeDetails *collectionChanges = dic[@"collectionChanges"];
        if (collectionChanges) {
            if ([collectionChanges hasIncrementalChanges]) {
                
                if (collectionChanges.insertedObjects.count > 0) {
                    [self.collectionView reloadData];
                    [self setupNavRightBtn];
                    [self scrollViewDidScroll:self.collectionView];
                }
                
                if (collectionChanges.removedObjects.count > 0) {
                    [self.collectionView reloadData];
                    [self setupNavRightBtn];
                    [self scrollViewDidScroll:self.collectionView];
                    if (self.modelList.count == 0) {
                        self.selectedBtn.selected = NO;
                    }
                }
            }
        }
    }
}

- (void)dismissClick {
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
    if (cell.model.type == HXPhotoModelMediaTypePhotoGif) {
        [cell stopGifImage];
    }else if (cell.model.type == HXPhotoModelMediaTypeLivePhoto) {
        [cell stopLivePhoto];
    }
    if (self.livePhotoCell) {
        [self.livePhotoCell stopLivePhoto];
    }
    if (cell.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:cell.requestID];
    }
    if (cell.longRequestId) {
        [[PHImageManager defaultManager] cancelImageRequest:cell.longRequestId];
    }
    if (cell.liveRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:cell.liveRequestID];
    } 
    self.livePhotoCell = nil;
    
    if (self.selectedComplete) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    } 
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.modelList.count;
} 
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoPreviewViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cellId" forIndexPath:indexPath];
    cell.model = self.modelList[indexPath.item];
    return cell;
}
- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    HXPhotoPreviewViewCell *myCell = (HXPhotoPreviewViewCell *)cell;
    if (myCell.requestID) {
        [[PHImageManager defaultManager] cancelImageRequest:myCell.requestID];
    }
    if (myCell.longRequestId) {
        [[PHImageManager defaultManager] cancelImageRequest:myCell.longRequestId];
    }
    if (myCell.liveRequestID) {
        [[PHImageManager defaultManager] cancelImageRequest:myCell.liveRequestID]; 
    }
    if (myCell.model.type == HXPhotoModelMediaTypePhotoGif) {
        [myCell stopGifImage];
    }else if (myCell.model.type == HXPhotoModelMediaTypeLivePhoto) {
        [myCell stopLivePhoto];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    CGFloat offsetx = scrollView.contentOffset.x;
    NSInteger currentIndex = (offsetx + (width + 20) * 0.5) / (width + 20);
    if (currentIndex > self.modelList.count - 1) {
        currentIndex = self.modelList.count - 1;
    }
    if (currentIndex < 0) {
        currentIndex = 0;
    }
    if (self.modelList.count == 0) {
        self.titleLb.text = @"0/0";
    }else {
        self.titleLb.text = [NSString stringWithFormat:@"%ld/%ld",currentIndex + 1,(unsigned long)self.modelList.count];
    }
    if (self.modelList.count > 0) {
        HXPhotoModel *model = self.modelList[currentIndex];
        self.selectedBtn.selected = model.selected;
    }
    self.index = currentIndex;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    HXPhotoModel *model = self.modelList[self.index];
    self.currentModel = model;
    if (model.isCloseLivePhoto) {
        return;
    }
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
    if (model.type == HXPhotoModelMediaTypeLivePhoto) {
        [cell startLivePhoto];
        self.livePhotoCell = cell;
    }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
        [cell startGifImage];
    }else {
        if (!model.previewPhoto) {
            [cell fetchLongPhoto];
        }
    } 
}

- (UILabel *)titleLb {
    if (!_titleLb) {
        _titleLb = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
        _titleLb.textColor = self.manager.UIManager.navTitleColor;
        _titleLb.font = [UIFont boldSystemFontOfSize:17];
        _titleLb.textAlignment = NSTextAlignmentCenter;
        _titleLb.text = [NSString stringWithFormat:@"%ld/%ld",self.index + 1,(unsigned long)self.modelList.count];
    }
    return _titleLb;
}

- (UIButton *)selectedBtn {
    if (!_selectedBtn) {
        CGFloat width = [UIScreen mainScreen].bounds.size.width;
        _selectedBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_selectedBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.cellSelectBtnNormalImageName] forState:UIControlStateNormal];
        [_selectedBtn setImage:[HXPhotoTools hx_imageNamed:self.manager.UIManager.cellSelectBtnSelectedImageName] forState:UIControlStateSelected];
        CGFloat selectedBtnW = _selectedBtn.currentImage.size.width;
        CGFloat selectedBtnH = _selectedBtn.currentImage.size.height;
        _selectedBtn.frame = CGRectMake(width - 30 - selectedBtnW, kNavigationBarHeight + 20, selectedBtnW, selectedBtnH);
        [_selectedBtn addTarget:self action:@selector(didSelectedClick:) forControlEvents:UIControlEventTouchUpInside];
        [_selectedBtn setEnlargeEdgeWithTop:20 right:20 bottom:20 left:20];
    }
    return _selectedBtn;
}

- (void)selectClick {
    HXPhotoModel *model = self.modelList[self.index];
    if (!self.selectedBtn.selected && !model.selected) {
        [self didSelectedClick:self.selectedBtn];
    }
}
    
- (BOOL) isSameWeekWithDate:(NSDate *)date {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        int unit = NSCalendarUnitWeekday | NSCalendarUnitMonth | NSCalendarUnitYear | kCFCalendarUnitDay ;
        
        //1.获得当前时间的 年月日
        NSDateComponents *nowCmps = [calendar components:unit fromDate:[NSDate date]];
        NSDateComponents *sourceCmps = [calendar components:unit fromDate:date];
        
        // 对比时间差
        NSDateComponents *dateCom = [calendar components:unit fromDate:[NSDate date] toDate:date options:0];
        NSInteger subDay = labs(dateCom.day);
        NSInteger subMonth = labs(dateCom.month);
        NSInteger subYear = labs(dateCom.year);
        
        if (subYear == 0 && subMonth == 0) { //当相关的差值等于零的时候说明在一个年、月、日的时间范围内，不是按照零点到零点的时间算的
            if (subDay > 6) { //相差天数大于6肯定不在一周内
                return NO;
            } else { //相差的天数大于或等于后面的时间所对应的weekday则不在一周内
                if (dateCom.day >= 0 && dateCom.hour >=0 && dateCom.minute >= 0) { //比较的时间大于当前时间
                    //西方一周的开始是从周日开始算的，周日是1，周一是2，而我们是从周一开始算新的一周
                    NSInteger chinaWeekday = sourceCmps.weekday == 1 ? 7 : sourceCmps.weekday - 1;
                    if (subDay >= chinaWeekday) {
                        return NO;
                    } else {
                        return YES;
                    }
                } else {
                    NSInteger chinaWeekday = sourceCmps.weekday == 1 ? 7 : nowCmps.weekday - 1;
                    if (subDay >= chinaWeekday) { //比较的时间比当前时间小，已经过去的时间
                        return NO;
                    } else {
                        return YES;
                    }
                }
            }
        } else { //时间范围差值超过了一年或一个月的时间范围肯定就不在一个周内了
            return NO;
        }
    }
    
- (void)didSelectedClick:(UIButton *)button {
    if (self.modelList.count == 0) {
        [self.view showImageHUDText:[NSBundle hx_localizedStringForKey:@"没有照片可选!"]];
        return;
    }
    HXPhotoModel *model = self.modelList[self.index];
//    判断image的创建时间是否在今天的前后3天内，若不是不能选择此照片
    if (![self isSameWeekWithDate:model.creationDate]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:@"此照片拍摄时间很久了，请选择其他照片" preferredStyle:UIAlertControllerStyleAlert];
        [self presentViewController:alert animated:YES completion:nil];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"好的" style:0 handler:nil];
        [alert addAction:action];
    }else {
        if (!button.selected) {
            NSString *str = [HXPhotoTools maximumOfJudgment:model manager:self.manager];
            if (str) {
                [self.view showImageHUDText:str];
                return;
            }
            if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
                HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
                if (cell) {
                    if (model.type == HXPhotoModelMediaTypePhotoGif) {
                        if (cell.imageView.image.images.count > 0) {
                            model.thumbPhoto = cell.imageView.image.images.firstObject;
                            model.previewPhoto = cell.imageView.image.images.firstObject;
                        }else {
                            model.thumbPhoto = cell.imageView.image;
                            model.previewPhoto = cell.imageView.image;
                        }
                    }else {
                        model.thumbPhoto = cell.imageView.image;
                        model.previewPhoto = cell.imageView.image;
                    }
                }else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        HXPhotoPreviewViewCell *cell_1 = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
                        if (model.type == HXPhotoModelMediaTypePhotoGif) {
                            model.thumbPhoto = cell_1.firstImage;
                            model.previewPhoto = cell_1.firstImage;
                        }else {
                            model.thumbPhoto = cell_1.imageView.image;
                            model.previewPhoto = cell_1.imageView.image;
                        }
                    });
                }
            }
            if (model.type == HXPhotoModelMediaTypePhoto || (model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                [self.manager.selectedPhotos addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeVideo) {
                [self.manager.selectedVideos addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                [self.manager.selectedPhotos addObject:model];
                [self.manager.selectedCameraPhotos addObject:model];
                [self.manager.selectedCameraList addObject:model];
            }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                [self.manager.selectedVideos addObject:model];
                [self.manager.selectedCameraVideos addObject:model];
                [self.manager.selectedCameraList addObject:model];
            }
            [self.manager.selectedList addObject:model];
            CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            anim.duration = 0.25;
            anim.values = @[@(1.2),@(0.8),@(1.1),@(0.9),@(1.0)];
            [button.layer addAnimation:anim forKey:@""];
        }else {
            if (model.type != HXPhotoModelMediaTypeCameraVideo && model.type != HXPhotoModelMediaTypeCameraPhoto) {
                model.thumbPhoto = nil;
                model.previewPhoto = nil;
            }
            if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeVideo || model.type == HXPhotoModelMediaTypeLivePhoto)) {
                if (model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif || model.type == HXPhotoModelMediaTypeLivePhoto) {
                    [self.manager.selectedPhotos removeObject:model];
                }else if (model.type == HXPhotoModelMediaTypeVideo) {
                    [self.manager.selectedVideos removeObject:model];
                }
            }else if (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeCameraVideo) {
                if (model.type == HXPhotoModelMediaTypeCameraPhoto) {
                    [self.manager.selectedPhotos removeObject:model];
                    [self.manager.selectedCameraPhotos removeObject:model];
                }else if (model.type == HXPhotoModelMediaTypeCameraVideo) {
                    [self.manager.selectedVideos removeObject:model];
                    [self.manager.selectedCameraVideos removeObject:model];
                }
                [self.manager.selectedCameraList removeObject:model];
            }
            [self.manager.selectedList removeObject:model];
        }
        button.selected = !button.selected;
        model.selected = button.selected;
        
        if (self.manager.selectedList.count > 0) {
            self.navItem.rightBarButtonItem.enabled = YES;
            [self.rightBtn setTitle:[NSString stringWithFormat:@"%@(%ld)",[NSBundle hx_localizedStringForKey:@"下一步"],(unsigned long)self.manager.selectedList.count] forState:UIControlStateNormal];
            [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
            self.rightBtn.layer.borderWidth = 0;
            CGFloat rightBtnH = self.rightBtn.frame.size.height;
            CGFloat rightBtnW = [HXPhotoTools getTextWidth:self.rightBtn.currentTitle height:rightBtnH fontSize:14];
            self.rightBtn.frame = CGRectMake(0, 0, rightBtnW + 20, rightBtnH);
        }else {
            [self.rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
            [self.rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnNormalBgColor];
            self.rightBtn.frame = CGRectMake(0, 0, 60, 25);
            self.rightBtn.layer.borderWidth = 0;
        }
        if ([self.delegate respondsToSelector:@selector(didSelectedClick:AddOrDelete:)]) {
            [self.delegate didSelectedClick:model AddOrDelete:button.selected];
        }
    }
}

- (UIButton *)rightBtn {
    if (!_rightBtn) {
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:[NSBundle hx_localizedStringForKey:@"下一步"] forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnNormalTitleColor forState:UIControlStateNormal];
        [_rightBtn setTitleColor:self.manager.UIManager.navRightBtnDisabledTitleColor forState:UIControlStateDisabled];
        [_rightBtn setTitleColor:[[UIColor lightGrayColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
        _rightBtn.layer.masksToBounds = YES;
        _rightBtn.layer.cornerRadius = 2;
        _rightBtn.layer.borderWidth = 0.5;
        _rightBtn.layer.borderColor = self.manager.UIManager.navRightBtnBorderColor.CGColor;
        [_rightBtn setBackgroundColor:self.manager.UIManager.navRightBtnDisabledBgColor];
        [_rightBtn addTarget:self action:@selector(didNextClick:) forControlEvents:UIControlEventTouchUpInside];
        _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _rightBtn.frame = CGRectMake(0, 0, 60, 25);
    }
    return _rightBtn;
}

- (void)didNextClick:(UIButton *)button {
    if (self.modelList.count == 0) {
        [self.view showImageHUDText:@"没有照片可选!"];
        return;
    }
    HXPhotoModel *model = self.modelList[self.index];
    BOOL max = NO;
    if (self.manager.selectedList.count == self.manager.maxNum) {
        // 已经达到最大选择数
        max = YES;
    }
    if (self.manager.type == HXPhotoManagerSelectedTypePhotoAndVideo) {
        if ((model.type == HXPhotoModelMediaTypePhoto || model.type == HXPhotoModelMediaTypePhotoGif) || (model.type == HXPhotoModelMediaTypeCameraPhoto || model.type == HXPhotoModelMediaTypeLivePhoto)) {
            if (self.manager.videoMaxNum > 0) {
                if (!self.manager.selectTogether) { // 是否支持图片视频同时选择
                    if (self.manager.selectedVideos.count > 0 ) {
                        // 已经选择了视频,不能再选图片
                        max = YES;
                    }
                }
            }
            if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
                max = YES;
                // 已经达到图片最大选择数
            }
        }
    }else if (self.manager.type == HXPhotoManagerSelectedTypePhoto) {
        if (self.manager.selectedPhotos.count == self.manager.photoMaxNum) {
            // 已经达到图片最大选择数
            max = YES;
        }
    }
//    if (self.isPreview) {
    /*静静加 注释他是为了预览选择下一步 不自动添加第一张图片
     if (self.manager.selectedList.count == 0) {
     if (!self.selectedBtn.selected && !max && self.modelList.count > 0) {
     model.selected = YES;
     HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
     model.thumbPhoto = cell.imageView.image;
     model.previewPhoto = cell.imageView.image;
     [self.manager.selectedList addObject:model];
     [self.manager.selectedPhotos addObject:model];
     }
     }
     */
    
//    }
    if ([self.delegate respondsToSelector:@selector(previewDidNextClick)]) {
        [self.delegate previewDidNextClick];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    HXPhotoModel *model = self.modelList[self.index];
    self.currentModel = model;
    if (model.isCloseLivePhoto) {
        return;
    }
    HXPhotoPreviewViewCell *cell = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
    
    if (!cell) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            HXPhotoPreviewViewCell *cell_1 = (HXPhotoPreviewViewCell *)[self.collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.index inSection:0]];
            if (model.type == HXPhotoModelMediaTypeLivePhoto) {
                [cell_1 startLivePhoto];
                self.livePhotoCell = cell_1;
            }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
                [cell_1 startGifImage];
            }else {
                [cell_1 fetchLongPhoto];
            }
        });
    }else {
        if (model.type == HXPhotoModelMediaTypeLivePhoto) {
            [cell startLivePhoto];
            self.livePhotoCell = cell;
        }else if (model.type == HXPhotoModelMediaTypePhotoGif) {
            [cell startGifImage];
        }else {
            [cell fetchLongPhoto];
        }
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC{
    if (operation == UINavigationControllerOperationPush) {
        return [HXTransition transitionWithType:HXTransitionTypePush VcType:HXTransitionVcTypePhoto];
    }else {
        return [HXTransition transitionWithType:HXTransitionTypePop VcType:HXTransitionVcTypePhoto];
    }
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypePresent VcType:HXPresentTransitionVcTypePhoto withPhotoView:self.photoView];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed{
    return [HXPresentTransition transitionWithTransitionType:HXPresentTransitionTypeDismiss VcType:HXPresentTransitionVcTypePhoto withPhotoView:self.photoView];
}

- (void)dealloc {
    NSSLog(@"dealloc");
}

@end
