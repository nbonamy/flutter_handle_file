#import "HandleFilePlugin.h"

static NSString *const kMessagesChannel = @"flutter_handle_file/messages";
static NSString *const kEventsChannel = @"flutter_handle_file/events";

@interface HandleFilePlugin () <FlutterStreamHandler>
@property(nonatomic, copy) NSString *initialFile;
@property(nonatomic, copy) NSString *latestFile;
@end

@implementation HandleFilePlugin {
  FlutterEventSink _eventSink;
}

static id _instance;

+ (HandleFilePlugin *)sharedInstance {
  if (_instance == nil) {
    _instance = [[HandleFilePlugin alloc] init];
  }
  return _instance;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  HandleFilePlugin *instance = [HandleFilePlugin sharedInstance];

  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:kMessagesChannel
                                  binaryMessenger:[registrar messenger]];
  [registrar addMethodCallDelegate:instance channel:channel];

  FlutterEventChannel *chargingChannel =
      [FlutterEventChannel eventChannelWithName:kEventsChannel
                                binaryMessenger:[registrar messenger]];
  [chargingChannel setStreamHandler:instance];

  [registrar addApplicationDelegate:instance];
}

- (void)setLatestFile:(NSString *)latestFile {
  static NSString *key = @"latestFile";

  [self willChangeValueForKey:key];
  _latestFile = [latestFile copy];
  [self didChangeValueForKey:key];

  if (_eventSink) _eventSink(_latestFile);
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  NSURL *url = (NSURL *)launchOptions[UIApplicationLaunchOptionsURLKey];
  self.initialFile = [url absoluteString];
  self.latestFile = self.initialFile;
  return YES;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  self.latestFile = [url absoluteString];
  return YES;
}

- (BOOL)application:(UIApplication *)application
    continueUserActivity:(NSUserActivity *)userActivity
      restorationHandler:(void (^)(NSArray *_Nullable))restorationHandler {
  if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
    self.latestFile = [userActivity.webpageURL absoluteString];
    if (!_eventSink) {
      self.initialFile = self.latestFile;
    }
    return YES;
  }
  return NO;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"getInitialFile" isEqualToString:call.method]) {
    result(self.initialFile);
    // } else if ([@"getLatestFile" isEqualToString:call.method]) {
    //     result(self.latestFile);
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (FlutterError *_Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(nonnull FlutterEventSink)eventSink {
  _eventSink = eventSink;
  return nil;
}

- (FlutterError *_Nullable)onCancelWithArguments:(id _Nullable)arguments {
  _eventSink = nil;
  return nil;
}

@end
