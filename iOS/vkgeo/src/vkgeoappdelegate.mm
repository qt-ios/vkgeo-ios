#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocationManager.h>
#import <CoreLocation/CLLocationManagerDelegate.h>

#import <VKSdkFramework/VKSdkFramework.h>

#include <QtCore/QtGlobal>
#include <QtCore/QString>
#include <QtCore/QDebug>

#include "vkhelpershared.h"

static const QString VK_APP_ID("6459902");

@interface QIOSApplicationDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>
@end

@interface QIOSApplicationDelegate (VKGeoAppDelegate)
@end

@implementation QIOSApplicationDelegate (VKGeoAppDelegate)

static CLLocationManager *LocationManager;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    Q_UNUSED(application)
    Q_UNUSED(launchOptions)

    [VKSdk initializeWithAppId:VK_APP_ID.toNSString()];

    VKHelperShared = new VKHelper();

    LocationManager = [[CLLocationManager alloc] init];

    LocationManager.allowsBackgroundLocationUpdates    = YES;
    LocationManager.pausesLocationUpdatesAutomatically = NO;
    LocationManager.desiredAccuracy                    = kCLLocationAccuracyHundredMeters;
    LocationManager.delegate                           = self;

    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways) {
        [LocationManager startUpdatingLocation];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    Q_UNUSED(application)

    [VKSdk processOpenURL:url fromApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]];

    return YES;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    Q_UNUSED(manager)

    if (locations != nil && locations.lastObject != nil) {
        CLLocation *location = locations.lastObject;

        if (VKHelperShared != NULL) {
            VKHelperShared->reportCoordinate(location.coordinate.latitude, location.coordinate.longitude);
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    Q_UNUSED(manager)

    qWarning() << QString::fromNSString([error localizedDescription]);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    Q_UNUSED(manager)

    if (status == kCLAuthorizationStatusAuthorizedAlways) {
        [LocationManager startUpdatingLocation];
    } else {
        [LocationManager stopUpdatingLocation];
    }
}

@end
