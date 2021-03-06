#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

#include <QtCore/QtGlobal>
#include <QtCore/QtMath>
#include <QtCore/QDebug>

#include "admobhelper.h"

const QString AdMobHelper::ADMOB_APP_ID              ("ca-app-pub-2455088855015693~9304224395");
const QString AdMobHelper::ADMOB_BANNERVIEW_UNIT_ID  ("ca-app-pub-2455088855015693/6159186300");
const QString AdMobHelper::ADMOB_INTERSTITIAL_UNIT_ID("ca-app-pub-2455088855015693/6215026625");
const QString AdMobHelper::ADMOB_TEST_DEVICE_ID      ("");

AdMobHelper *AdMobHelper::Instance = nullptr;

@interface BannerViewDelegate : NSObject<GADBannerViewDelegate>

- (id)init;
- (void)dealloc;
- (void)loadAd;

@end

@implementation BannerViewDelegate
{
    GADBannerView *BannerView;
}

- (id)init
{
    self = [super init];

    if (self) {
        UIViewController * __block root_view_controller = nil;

        [UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = window.rootViewController;

            *stop = (root_view_controller != nil);
        }];

        BannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];

        BannerView.adUnitID           = AdMobHelper::ADMOB_BANNERVIEW_UNIT_ID.toNSString();
        BannerView.autoloadEnabled    = YES;
        BannerView.rootViewController = root_view_controller;
        BannerView.delegate           = self;

        if (@available(iOS 6, *)) {
            BannerView.translatesAutoresizingMaskIntoConstraints = NO;
        } else {
            assert(0);
        }

        [root_view_controller.view addSubview:BannerView];

        if (@available(iOS 11, *)) {
            UILayoutGuide *guide = root_view_controller.view.safeAreaLayoutGuide;

            [NSLayoutConstraint activateConstraints:@[
                [BannerView.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
                [BannerView.topAnchor     constraintEqualToAnchor:guide.topAnchor]
            ]];

            CGSize  status_bar_size   = UIApplication.sharedApplication.statusBarFrame.size;
            CGFloat status_bar_height = qMin(status_bar_size.width, status_bar_size.height);

            AdMobHelper::setBannerViewHeight(qFloor(BannerView.frame.size.height + root_view_controller.view.safeAreaInsets.top
                                                                                 - status_bar_height));
        } else {
            assert(0);
        }
    }

    return self;
}

- (void)dealloc
{
    [BannerView removeFromSuperview];
    [BannerView release];

    [super dealloc];
}

- (void)loadAd
{
    GADRequest *request = [GADRequest request];

    if (AdMobHelper::ADMOB_TEST_DEVICE_ID != "") {
        request.testDevices = @[ AdMobHelper::ADMOB_TEST_DEVICE_ID.toNSString() ];
    }

    [BannerView loadRequest:request];
}

- (void)adViewDidReceiveAd:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView
{
    Q_UNUSED(adView)
}

- (void)adView:(GADBannerView *)adView didFailToReceiveAdWithError:(GADRequestError *)error
{
    Q_UNUSED(adView)

    qWarning() << QString::fromNSString(error.localizedDescription);

    [self performSelector:@selector(loadAd) withObject:nil afterDelay:10.0];
}

@end

@interface InterstitialDelegate : NSObject<GADInterstitialDelegate>

- (id)init;
- (void)dealloc;
- (void)loadAd;
- (void)show;
- (BOOL)isReady;

@end

@implementation InterstitialDelegate
{
    GADInterstitial *Interstitial;
}

- (id)init
{
    self = [super init];

    if (self) {
        Interstitial = nil;
    }

    return self;
}

- (void)dealloc
{
    if (Interstitial != nil) {
        [Interstitial release];
    }

    [super dealloc];
}

- (void)loadAd
{
    if (Interstitial != nil) {
        [Interstitial release];
    }

    Interstitial = [[GADInterstitial alloc] initWithAdUnitID:AdMobHelper::ADMOB_INTERSTITIAL_UNIT_ID.toNSString()];

    Interstitial.delegate = self;

    GADRequest *request = [GADRequest request];

    if (AdMobHelper::ADMOB_TEST_DEVICE_ID != "") {
        request.testDevices = @[ AdMobHelper::ADMOB_TEST_DEVICE_ID.toNSString() ];
    }

    [Interstitial loadRequest:request];
}

- (void)show
{
    if (Interstitial != nil && Interstitial.isReady) {
        UIViewController * __block root_view_controller = nil;

        [UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(UIWindow * _Nonnull window, NSUInteger, BOOL * _Nonnull stop) {
            root_view_controller = window.rootViewController;

            *stop = (root_view_controller != nil);
        }];

        [Interstitial presentFromRootViewController:root_view_controller];
    }
}

- (BOOL)isReady
{
    if (Interstitial != nil) {
        return Interstitial.isReady;
    } else {
        return NO;
    }
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    Q_UNUSED(ad)
}

- (void)interstitialWillPresentScreen:(GADInterstitial *)ad
{
    Q_UNUSED(ad)

    AdMobHelper::setInterstitialActive(true);
}

- (void)interstitialWillDismissScreen:(GADInterstitial *)ad
{
    Q_UNUSED(ad)
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad
{
    Q_UNUSED(ad)

    AdMobHelper::setInterstitialActive(false);

    [self performSelector:@selector(loadAd) withObject:nil afterDelay:10.0];
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad
{
    Q_UNUSED(ad)
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error
{
    Q_UNUSED(ad)

    qWarning() << QString::fromNSString(error.localizedDescription);

    [self performSelector:@selector(loadAd) withObject:nil afterDelay:10.0];
}

@end

AdMobHelper::AdMobHelper(QObject *parent) : QObject(parent)
{
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];

    InterstitialActive           = false;
    BannerViewHeight             = 0;
    Instance                     = this;
    BannerViewDelegateInstance   = nullptr;
    InterstitialDelegateInstance = [[InterstitialDelegate alloc] init];

    [InterstitialDelegateInstance loadAd];
}

AdMobHelper::~AdMobHelper() noexcept
{
    if (BannerViewDelegateInstance != nullptr && BannerViewDelegateInstance != nil) {
        [BannerViewDelegateInstance release];
    }

    [InterstitialDelegateInstance release];
}

bool AdMobHelper::interstitialReady() const
{
    return [InterstitialDelegateInstance isReady];
}

bool AdMobHelper::interstitialActive() const
{
    return InterstitialActive;
}

int AdMobHelper::bannerViewHeight() const
{
    return BannerViewHeight;
}

void AdMobHelper::showBannerView()
{
    if (BannerViewDelegateInstance != nullptr && BannerViewDelegateInstance != nil) {
        [BannerViewDelegateInstance release];

        BannerViewHeight = 0;

        emit bannerViewHeightChanged(BannerViewHeight);

        BannerViewDelegateInstance = nil;
    }

    BannerViewDelegateInstance = [[BannerViewDelegate alloc] init];

    [BannerViewDelegateInstance loadAd];
}

void AdMobHelper::hideBannerView()
{
    if (BannerViewDelegateInstance != nullptr && BannerViewDelegateInstance != nil) {
        [BannerViewDelegateInstance release];

        BannerViewHeight = 0;

        emit bannerViewHeightChanged(BannerViewHeight);

        BannerViewDelegateInstance = nil;
    }
}

void AdMobHelper::showInterstitial()
{
    [InterstitialDelegateInstance show];
}

void AdMobHelper::setInterstitialActive(bool active)
{
    Instance->InterstitialActive = active;

    emit Instance->interstitialActiveChanged(Instance->InterstitialActive);
}

void AdMobHelper::setBannerViewHeight(int height)
{
    Instance->BannerViewHeight = height;

    emit Instance->bannerViewHeightChanged(Instance->BannerViewHeight);
}
