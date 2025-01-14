#import "OoniRunViewController.h"
#import "DictionaryUtility.h"
#import "TestUtility.h"
#import "LocalizationUtility.h"
#import "MessageUtility.h"
#import "TestRunningViewController.h"
#import "ReachabilityManager.h"

@interface OoniRunViewController ()

@end

@implementation OoniRunViewController
@synthesize testName, testArguments, testDescription;
@synthesize url;

- (void)viewDidLoad {
    [super viewDidLoad];
    [NavigationBarUtility setNavigationBar:self.navigationController.navigationBar color:[UIColor colorNamed:@"color_gray2"]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTest:) name:@"reloadTest" object:nil];
    [self handleUrlScheme];
}


-(void)reloadTest:(NSNotification *)notification{
    urls = nil;
    testName = nil;
    testArguments = nil;
    testDescription = nil;
    [self.tableView setHidden:YES];
    NSDictionary *parameters = notification.userInfo;
    url = [parameters objectForKey:@"url"];
    [self handleUrlScheme];
}

-(IBAction)close:(id)sender{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)handleUrlScheme{
    NSDictionary *dict = [DictionaryUtility parseQueryString:[url query]];
     //Logging
     NSLog(@"url recieved: %@", url);
     NSLog(@"query string: %@", [url query]);
     NSLog(@"host: %@", [url host]);
     NSLog(@"url path: %@", [url path]);
     NSLog(@"dict: %@", dict);
    
    NSString *action;
    if ([[url host] isEqualToString:@"run.ooni.io"])
        action = [[url path] substringFromIndex:1];
    else
        action = [url host];
    if ([action isEqualToString:@"nettest"]){
        //creating parameters dict
        NSDictionary *parameters = [DictionaryUtility getParametersFromDict:dict];
        NSLog(@"parameters: %@", parameters);
        if ([self checkMv:parameters]){
            if ([parameters objectForKey:@"tn"] && [TestUtility getCategoryForTest:[parameters objectForKey:@"tn"]]){
                [self setTestName:[parameters objectForKey:@"tn"]];
                if ([parameters objectForKey:@"ta"])
                    [self setTestArguments:[parameters objectForKey:@"ta"]];
                [self showTestScreen];
            }
            else {
                [self showErrorScreen];
            }
        }
    }
    else {
        [self showErrorScreen];
    }
}

- (BOOL)checkMv:(NSDictionary*)parameters{
    NSString *minimum_version = [parameters objectForKey:@"mv"];
    if (minimum_version != nil){
        if ([minimum_version compare:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] options:NSNumericSearch] == NSOrderedDescending) {
            //actualVersion is lower than the requiredVersion
            [self showUpdateScreen];
            return NO;
        }
        else {
            return YES;
        }
    }
    else {
        [self showErrorScreen];
        return NO;
    }
}

- (void)showUpdateScreen{
    [self.titleLabel setText:NSLocalizedString(@"OONIRun.OONIProbeOutOfDate", nil)];
    [self.subtitleLabel setText:NSLocalizedString(@"OONIRun.OONIProbeNewerVersion", nil)];
    [self.runButton setTitle:NSLocalizedString(@"OONIRun.Update", nil) forState:UIControlStateNormal];
    [self.runButton addTarget:self
                       action:@selector(updateApp) forControlEvents:UIControlEventTouchUpInside];
    [self.headerImage setImage:[UIImage imageNamed:@"update"]];
    [self.footerImage setImage:[UIImage imageNamed:@"update"]];
}

- (void)updateApp{
    NSString *iTunesLink = @"itms://itunes.apple.com/us/app/apple-store/id1199566366?mt=8";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:iTunesLink]];
}

- (void)showErrorScreen{
    [self.titleLabel setText:NSLocalizedString(@"OONIRun.InvalidParameter", nil)];
    [self.subtitleLabel setText:NSLocalizedString(@"OONIRun.InvalidParameter.Msg", nil)];
    [self.runButton setTitle:NSLocalizedString(@"OONIRun.Close", nil)
                    forState:UIControlStateNormal];
    [self.runButton addTarget:self
                       action:@selector(close:) forControlEvents:UIControlEventTouchUpInside];
    [self.headerImage setImage:[UIImage imageNamed:@"question_mark"]];
    [self.footerImage setImage:[UIImage imageNamed:@"question_mark"]];
}

- (void)showTestScreen{
    [self.titleLabel setText:[LocalizationUtility getNameForTest:self.testName]];
    
    if (testDescription != nil)
        [self.subtitleLabel setText:[NSString stringWithFormat:@"%@", testDescription]];
    else
        [self.subtitleLabel setText:NSLocalizedString(@"OONIRun.YouAreAboutToRun", nil)];
    
    [self.runButton setTitle:NSLocalizedString(@"OONIRun.Run", nil) forState:UIControlStateNormal];
    [self.runButton addTarget:self
                       action:@selector(runTest) forControlEvents:UIControlEventTouchUpInside];
    
    [self.headerImage setImage:[UIImage imageNamed:[TestUtility getCategoryForTest:self.testName]]];
    [self.footerImage setImage:[UIImage imageNamed:[TestUtility getCategoryForTest:self.testName]]];

    //reset the arrays: we may be called more than once for the same screen
    if ([testName isEqualToString:@"web_connectivity"]){
        urls = [[NSMutableArray alloc] init];
        //First validate urls
        if ([testArguments isKindOfClass:[NSDictionary class]]){
        id urlsObj = [testArguments objectForKey:@"urls"];
            if ([urlsObj isKindOfClass:[NSArray class]] && [(NSArray*)urlsObj count] > 0){
                [self validateURLs];
            }
        }
        //then load view
        if ([urls count] > 0){
            self.tableView.estimatedRowHeight = 44.0;
            self.tableView.rowHeight = UITableViewAutomaticDimension;
            [self.tableView setHidden:NO];
            [self.randomlistLabel setHidden:YES];
            //reloading the view with new parameters.
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
        else {
            [self.tableView setHidden:YES];
            [self.randomlistLabel setText:NSLocalizedString(@"OONIRun.RandomSamplingOfURLs", nil)];
            [self.randomlistLabel setHidden:NO];
        }
    }
    else {
        [self.tableView setHidden:YES];
        [self.randomlistLabel setHidden:YES];
    }
}

-(void)validateURLs{
    for (NSString *url in [testArguments objectForKey:@"urls"]){
        if ([url length] < 2083){
            [Url checkExistingUrl:url];
            [urls addObject:url];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [urls count];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedFormatString(@"OONIRun.URLs", [NSString stringWithFormat:@"%ld", [urls count]]);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.backgroundView.backgroundColor = [UIColor clearColor];
    header.textLabel.font = [UIFont fontWithName:@"FiraSans-Regular" size:18];
    [header.textLabel setTextColor:[UIColor colorNamed:@"color_gray9"]];
    header.textLabel.text = NSLocalizedFormatString(@"OONIRun.URLs", [NSString stringWithFormat:@"%ld", [urls count]]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    NSString *current = [urls objectAtIndex:indexPath.row];
    [cell.textLabel setTextColor:[UIColor colorNamed:@"color_gray9"]];
    cell.textLabel.text = current;
    return cell;
}


-(IBAction)runTest {
    if ([[ReachabilityManager sharedManager].reachability currentReachabilityStatus] != NotReachable)
        [self performSegueWithIdentifier:@"toTestRun" sender:self];
    else
        [MessageUtility alertWithTitle:NSLocalizedString(@"Modal.Error", nil)
                               message:NSLocalizedString(@"Modal.Error.NoInternet", nil) inView:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"toTestRun"]){
        TestRunningViewController *vc = (TestRunningViewController * )segue.destinationViewController;
        NSString *testSuiteName = [TestUtility getCategoryForTest:testName];
        AbstractSuite *testSuite = [[AbstractSuite alloc] initSuite:testSuiteName];
        AbstractTest *test = [[AbstractTest alloc] initTest:testName];
        [test setAnnotation:YES];
        [testSuite setTestList:[NSMutableArray arrayWithObject:test]];
        if ([testSuiteName isEqualToString:@"websites"] && [urls count] > 0)
            [(WebConnectivity*)test setInputs:urls];
        [vc setTestSuites:[NSMutableArray arrayWithObject:testSuite]];
        [vc setPresenting:YES];
    }
}

@end
