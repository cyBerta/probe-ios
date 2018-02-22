#import "ResultsHeaderViewController.h"

@interface ResultsHeaderViewController ()

@end

@implementation ResultsHeaderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addLine:self.view2];
    [self addLine:self.view3];
    [self.testsLabel setText:NSLocalizedString(@"tests", nil)];
    [self.networksLabel setText:NSLocalizedString(@"networks", nil)];
    [self.dataUsageLabel setText:NSLocalizedString(@"data_usage", nil)];
    filter = @"";
    

/*
    let query = Person.query()
    .limit(1000)
    .orderBy("Name")
    .offset(25)
    .batchSize(30)
    
    let numberOfPeople = query.count()
    let peopleBySurname = query.groupBy("surname")
    let totalAge = query.sumOf("age")
    
    //TODO reload in case of filter
    //SRKRawResults* results = [SharkORM rawQuery:@""];
    
    +(SRKRawResults*)rawQuery:(NSString*)sql;
    

    SRKResultSet* results = [[Result query] count]

    SRKResultSet* results = [[[Result query] sumOf:@"datausageUp"] ]


    SELECT SUM(datausageUp), SUM(datausageDown)
    FROM tabella
    WHERE date < "2017-01-01"

    ```SELECT
    COUNT(DISTINCT asn)
    FROM tabella
    ```
 */
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //TODO query every appear or send update every test?
    [self reloadQuery];
}

-(void)reloadQuery{
    SRKQuery *query;
    if ([filter length] > 0)
        query = [[[Result query] where:[NSString stringWithFormat:@"name = '%@'", filter]] orderByDescending:@"startTime"];
    else
        query = [[Result query] orderByDescending:@"startTime"];
    
    double dataUsageDown = [query sumOf:@"dataUsageDown"];
    double dataUsageUp = [query sumOf:@"dataUsageUp"];
    
    [self.upLabel setText:[NSByteCountFormatter stringFromByteCount:dataUsageUp countStyle:NSByteCountFormatterCountStyleFile]];
    [self.downLabel setText:[NSByteCountFormatter stringFromByteCount:dataUsageDown countStyle:NSByteCountFormatterCountStyleFile]];
    [self.numberTestsLabel setText:[NSString stringWithFormat:@"%llu", [query count]]];
    //TODO BUG this count also the nulls
    [self.numberNetworksLabel setText:[NSString stringWithFormat:@"%lu", [[query distinct:@"asn"] count]]];
    [self.delegate testFilter:query];
}

#pragma mark - MKDropdownMenuDataSource

- (NSInteger)numberOfComponentsInDropdownMenu:(MKDropdownMenu *)dropdownMenu {
    return 1;
}

- (NSInteger)dropdownMenu:(MKDropdownMenu *)dropdownMenu numberOfRowsInComponent:(NSInteger)component {
    return [[SettingsUtility getTestTypes] count]+1;
}

#pragma mark - MKDropdownMenuDelegate

- (CGFloat)dropdownMenu:(MKDropdownMenu *)dropdownMenu rowHeightForComponent:(NSInteger)component {
    return 44;
}

- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForComponent:(NSInteger)component{
    return NSLocalizedString(@"filter_tests", nil);
}
- (NSString *)dropdownMenu:(MKDropdownMenu *)dropdownMenu titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (row == 0)
        return NSLocalizedString(@"all_tests", nil);
    NSArray *tests =  [SettingsUtility getTestTypes];
    return NSLocalizedString([tests objectAtIndex:row-1], nil);
}

- (UIColor *)dropdownMenu:(MKDropdownMenu *)dropdownMenu backgroundColorForRow:(NSInteger)row forComponent:(NSInteger)component {
    if (row == 0 && [filter isEqualToString:@""])
        return [UIColor colorWithRGBHexString:color_gray5 alpha:1.0f];
    else if (row > 0 && [[[SettingsUtility getTestTypes] objectAtIndex:row-1] isEqualToString:filter])
        return [UIColor colorWithRGBHexString:color_gray5 alpha:1.0f];
    else
        return [UIColor whiteColor];
}

- (void)dropdownMenu:(MKDropdownMenu *)dropdownMenu didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSString *current = @"";
    if (row > 0){
        NSArray *tests =  [SettingsUtility getTestTypes];
        current = [tests objectAtIndex:row-1];
    }
    filter = current;
    [self reloadQuery];

    double delayInSeconds = 0.15;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.dropdownMenu closeAllComponentsAnimated:YES];
    });
}

-(void)addLine:(UIView*)view{
    UIView *lineView=[[UIView alloc]initWithFrame:CGRectMake(0, 0, 1, view.frame.size.height)];
    [lineView setBackgroundColor:[UIColor whiteColor]];
    [view addSubview:lineView];
}

@end