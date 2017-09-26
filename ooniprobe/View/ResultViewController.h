#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "ResultSelectorViewController.h"
#import "LogViewController.h"
#import "MBProgressHUD.h"

@interface ResultViewController : UIViewController <WKNavigationDelegate, UIAlertViewDelegate> {
    BOOL openBrowser;
    NSURL *openURL;
}

@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) IBOutlet NSString *testName;
@property (nonatomic, strong) NSString *log_file;

@end
