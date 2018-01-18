//
//  Demo8ViewController.m
//  微博照片选择
//
//  Created by 洪欣 on 2017/9/14.
//  Copyright © 2017年 洪欣. All rights reserved.
//

#import "Demo8ViewController.h" 
#import "HXPhotoView.h"
#import "HXDatePhotoToolManager.h"
static const CGFloat kPhotoViewMargin = 12.0;
@interface Demo8ViewController ()<HXPhotoViewDelegate>
@property (strong, nonatomic) HXPhotoManager *manager;
@property (strong, nonatomic) HXPhotoView *photoView;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (copy, nonatomic) NSArray *selectList;
<<<<<<< HEAD
@property (copy, nonatomic) NSArray *imageRequestIds;
@property (copy, nonatomic) NSArray *videoSessions;

@property (strong, nonatomic) HXDatePhotoToolManager *toolManager;
=======
>>>>>>> parent of 89c682d... v2.1.0  优化区分icloud照片、修改写入文件方法
@end

@implementation Demo8ViewController
- (HXPhotoManager *)manager {
    if (!_manager) {
        _manager = [[HXPhotoManager alloc] initWithType:HXPhotoManagerSelectedTypePhotoAndVideo];
        _manager.configuration.openCamera = YES;
        _manager.configuration.photoMaxNum = 9;
        _manager.configuration.videoMaxNum = 9;
        _manager.configuration.maxNum = 18;
    }
    return _manager;
}
- (HXDatePhotoToolManager *)toolManager {
    if (!_toolManager) {
        _toolManager = [[HXDatePhotoToolManager alloc] init];
    }
    return _toolManager;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    //    self.navigationController.navigationBar.translucent = NO;
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:scrollView];
    self.scrollView = scrollView;
    
    CGFloat width = scrollView.frame.size.width;
    HXPhotoView *photoView = [[HXPhotoView alloc] initWithFrame:CGRectMake(kPhotoViewMargin, kPhotoViewMargin, width - kPhotoViewMargin * 2, 0) manager:self.manager];
    photoView.delegate = self;
    photoView.backgroundColor = [UIColor whiteColor];
    [photoView refreshView];
    [scrollView addSubview:photoView];
    self.photoView = photoView;
    
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"写入Temp" style:UIBarButtonItemStylePlain target:self action:@selector(didNavOneBtnClick)];
    
    self.navigationItem.rightBarButtonItems = @[item1];
}

- (void)didNavOneBtnClick {
    [self.view showLoadingHUDText:@"写入中"];
    __weak typeof(self) weakSelf = self;
<<<<<<< HEAD
 
    [self.toolManager writeSelectModelListToTempPathWithList:self.selectList success:^(NSArray<NSURL *> *allURL, NSArray<NSURL *> *photoURL, NSArray<NSURL *> *videoURL) {
        NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allURL,photoURL,videoURL);
        NSURL *url = photoURL.firstObject;
        if (url) {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:url]];
            NSSLog(@"%@",image);
        }
=======
    [HXPhotoTools selectListWriteToTempPath:self.selectList completion:^(NSArray<NSURL *> *allUrl, NSArray<NSURL *> *imageUrls, NSArray<NSURL *> *videoUrls) {
        NSSLog(@"\nall : %@ \nimage : %@ \nvideo : %@",allUrl,imageUrls,videoUrls);
>>>>>>> parent of 89c682d... v2.1.0  优化区分icloud照片、修改写入文件方法
        [weakSelf.view handleLoading];
    } failed:^{
        [weakSelf.view handleLoading];
        [weakSelf.view showImageHUDText:@"写入失败"];
        NSSLog(@"写入失败");
    }];
}

- (void)photoView:(HXPhotoView *)photoView changeComplete:(NSArray<HXPhotoModel *> *)allList photos:(NSArray<HXPhotoModel *> *)photos videos:(NSArray<HXPhotoModel *> *)videos original:(BOOL)isOriginal {
    self.selectList = allList;
    NSSLog(@"%@",allList);
}

- (void)photoView:(HXPhotoView *)photoView updateFrame:(CGRect)frame {
    NSSLog(@"%@",NSStringFromCGRect(frame));
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, CGRectGetMaxY(frame) + kPhotoViewMargin);
    
}

@end
