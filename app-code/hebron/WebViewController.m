//
//  WebViewController.m
//  passagetells
//
//  Created by HoneyPanda on 8/26/15.
//  Copyright (c) 2015 Daisuke Nakazawa. All rights reserved.
//

#import "WebViewController.h"
#import "passagetells-Swift.h"
#import "Common.h"

@interface WebViewController () <UIWebViewDelegate, MBProgressHUDDelegate,CLLocationManagerDelegate>

@property (readwrite) BOOL needToReload;
@property (nonatomic, readwrite) MBProgressHUD *mbLoad;

@property (nonatomic, retain) NSMutableArray *mp3FileArray;

@property (readwrite) NSString *project_name;
@property (readwrite) NSString *project_id;
@property (readwrite) NSString *beaconsIDSelf;


@end

@implementation WebViewController

@synthesize mbLoad;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBarHidden = YES;
    
    // show loading indicator
    mbLoad = [[MBProgressHUD alloc] initWithView:self.view];
    mbLoad.labelText = @"Loading...";
    [self.view addSubview:mbLoad];
    [mbLoad setDelegate:self];
    [mbLoad show:YES];
//    self.webView.frame = CGRectMake(0, 50, 120, 460);

    
    self.webView.backgroundColor = [UIColor blackColor];
    self.webView.scalesPageToFit = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    self.webView.delegate = self;
    self.webView.scrollView.bounces = NO;
    
//    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]]];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOME_URL]]];
    
}
//- (void)checkAuth(){
//    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
//        switch alert number {
//        case 1: //password
//            println (“alert result - 1”)
//            let password = alertView.textFieldAtIndex(0)!.text
//            if password == passwordtoday {
//                println(“great”)
//                // save the password by NSUserDefaults
//                config.setObject(password, forKey:”PASSWORD”)
//                config.synchronize()
//                //release the password-lock in the process
//                ctrlrsv = 0
//                checkAuthorizationStatus ()
//            } else {
//                passwordchecker ()
//            }
//        case 2: //location service restricted/denied
//            println (“alert result - 2”)
//            let url = NSURL(string: UIApplicationOpenSettingsURLString)!
//            UIApplication.sharedApplication().openURL(url)
//            let alert = UIAlertView(title: “Location Service”, message: “Checking the availability of Location Service on the app.”, delegate: self, cancelButtonTitle: “OK” )
//            alertnumber = 3
//            alert.show()
//        case 3: //location service setting is changed
//            println (“alert result - 3”)
//            checkAuthorizationStatus ()
//        default:
//            break
//        }
//    }
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)resume{
    if (self.needToReload) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOME_URL]]];
    }
}

-(bool)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"clickedButtonAtIndex: %lu", (unsigned long)buttonIndex);
    if(buttonIndex == 0) {
        // "retry" selected: try to load "Top" page
        return [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:HOME_URL]]];
    }
    
    // "close" selected
    // XXX: reset
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request
 navigationType:(UIWebViewNavigationType)navigationType {
    
    NSLog(@"passagetells//");
    NSString *actionsAndParams = request.URL.lastPathComponent;
    NSString *query = request.URL.query;
    
    
    
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [query componentsSeparatedByString:@"&"];
    
    
    for (NSString *keyValuePair in urlComponents)
    {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        
        [queryStringDictionary setObject:value forKey:key];
    }
    
    NSLog(actionsAndParams);
    NSLog(query);
    
    NSLog(@"shouldStartLoadWithRequest: %@", [request.URL lastPathComponent]);
    if ([[request.URL scheme] isEqual:@"passagetells"]) { // TODO && uri contains download.
        
        NSLog(@"was path was...");
        if([actionsAndParams rangeOfString:@"selectProject"].location != NSNotFound) {
            NSLog(@"passagetells///selectProject action");
            
            //parse the url
            self.project_id = (NSString*)[queryStringDictionary objectForKey:@"id"];
            self.project_name = (NSString*)[queryStringDictionary objectForKey:@"name"];
            [[DataManager sharedManager] setProject_name:self.project_name];
            NSLog(self.project_id);
            NSLog(self.project_name);
            NSLog(@"was the project id");
            NSMutableString *projectURL = [NSMutableString stringWithString:HOME_URL];
            [ projectURL appendString:@"/"];
            [projectURL appendString:self.project_name];
            [projectURL appendString:@"/intro.html"];
            NSLog(projectURL);
            NSString *oururl = [NSString stringWithString:projectURL];
            NSLog(oururl);
            NSURL* url = [NSURL URLWithString: oururl];
            
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:30];
            
            [webView loadRequest:request];
            
            return NO;
        }else if ([actionsAndParams rangeOfString:@"download"].location != NSNotFound) {
            NSLog(@"passagetells///download action");
            
            // Get JSON files
            // BeaconID.JSON
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            
            
            // CtrlData.JSON
            [[[DataManager sharedManager] ctrlDatas] removeAllObjects];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [[AFNetManager sharedManager] sendGETRequestTo:BASE_URL path:@"ctrldata.json" params:@{} success:^(id successBlock) {
                
                NSString *theJson= [[NSString alloc] initWithData:successBlock encoding:NSUTF8StringEncoding];
                
                NSDictionary *dict = [theJson JSONValue];
                
                for (NSString *key in [dict allKeys]) {
                    NSString *value = [dict valueForKey:key];
                    
                    [[[DataManager sharedManager] ctrlDatas] addObject:[[CtrlData alloc] initWith:key ctrlVal:value]];
                }
                
            } error:^(NSError *error) {
                NSLog(@"Please check your internet connection.");
                
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            }];
            
            
            // Projects.JSON
            [[[DataManager sharedManager] projects] removeAllObjects];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            [[AFNetManager sharedManager] sendGETRequestTo:HOME_URL path:@"projects.json" params:@{} success:^(id successBlock) {
                
                NSString *theJson= [[NSString alloc] initWithData:successBlock encoding:NSUTF8StringEncoding];
                
                NSDictionary *dict = [theJson JSONValue];
                
                for (NSString *key in [dict allKeys]) {
                    NSString *value = [dict valueForKey:key];
                    
                    [[[DataManager sharedManager] projects] addObject:[[Projects alloc] initWith:[key intValue] name:value]];
                }
                
            } error:^(NSError *error) {
                NSLog(@"Please check your internet connection.");
                
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                
            }];
            
            
     
           
           
            
            

            
            
            ///////////// downloading beacons
            if([[[DataManager sharedManager] beaconID] count]==0){
                [[DataManager sharedManager] setBeaconID:[BeaconListner parseIntoDictionary]];
            }
            
            
            
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            NSUUID *proximityUUID = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
            
            
            CLBeaconRegion *region =         [[CLBeaconRegion alloc] initWithProximityUUID:proximityUUID identifier:@"EstimoteRegion"];
            
            [self.locationManager startRangingBeaconsInRegion:region];
            

            
            // mp3s
            [[[DataManager sharedManager] mp3FileNames] removeAllObjects];
            [MBProgressHUD showHUDAddedTo:self.view animated:YES];
            
            NSString *mp3sjsonurl = [NSString stringWithFormat:@"%@/%@/",HOME_URL,[[DataManager sharedManager] project_name]];
            NSLog(mp3sjsonurl);
            [[AFNetManager sharedManager] sendGETRequestTo:mp3sjsonurl path:@"mp3s.json" params:@{} success:^(id successBlock) {
                
                NSString *theJson= [[NSString alloc] initWithData:successBlock encoding:NSUTF8StringEncoding];
                NSLog(theJson);
                NSArray *array = [theJson JSONValue];
//                
//                for (NSString *key in [dict allKeys]) {
//                    //                    NSString *value = [dict valueForKey:key];
//                    NSLog(key);
//                    [[[DataManager sharedManager] mp3FileNames] addObject:key];
//                }
                [self downloadMp3s:array];
                
                
            } error:^(NSError *error) {
                NSLog(@"Please check your internet connection.");
                
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            }];
            
            
            
            
            

        }else  if([actionsAndParams rangeOfString:@"ok"].location != NSNotFound) {
            
            ViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"MainViewController"];
            [self.navigationController pushViewController:vc animated:YES];
            
        }
        return NO;
    } else if ([[request.URL scheme] isEqual:@"mailto"] || [[request.URL scheme] isEqual:@"tel"]) {
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    } else {
        
    }
    return YES;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"webViewDidFinishLoad: %@", [webView.request.URL lastPathComponent]);
//    
//    NSString* js =
//    @"var meta = document.createElement('meta'); " \
//    "meta.setAttribute( 'name', 'viewport' ); " \
//    "meta.setAttribute( 'content', 'width=760px' ); " \
//    "document.getElementsByTagName('head')[0].appendChild(meta)";
//    
//    [webView stringByEvaluatingJavaScriptFromString: js];
//
//    
    if (mbLoad != nil && !mbLoad.isHidden) {
        [mbLoad hide:YES];
    }
}

- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*) error {
    //NSLog(@"didFailLoadWithError");
    
    self.needToReload = YES;
    
    NSInteger code = [error code];
    if (code == NSURLErrorCancelled) {
        // ignore cancel by user
        return;
    }
    
    NSString *desc = @"通信できませんでした。\n再度お試しください。";
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Passagetells" message:desc delegate:self
                                          cancelButtonTitle:@"Retry" otherButtonTitles:@"Close", nil];
    [alert show];
}

#pragma mark -
#pragma mark MBProgressHUDDelegate methods
- (void)hudWasHidden:(MBProgressHUD *)hud {
    [mbLoad removeFromSuperview];
    mbLoad = nil;
}
-(void)downloadMp3s:(NSMutableArray *)mp3FileNames{
    NSMutableArray *savedFiles = [[DataManager sharedManager] mp3Files];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if(savedFiles != nil && [savedFiles count]!=0){
        Mp3File *savedFileFirst = savedFiles[0];
        if ([fileManager fileExistsAtPath:savedFileFirst.filePath]) { // yes
                NSLog(@"ファイル群は存在しています");
        } else {
                NSLog(@"ファイル群は存在していません");
            [[[DataManager sharedManager] mp3Files] removeAllObjects];
            savedFiles = [[DataManager sharedManager] mp3Files];
        }
       
    }


    self.mp3FileArray = [[NSMutableArray alloc] init];
    if ([savedFiles count] == 36) {
        [self gotoNextVC];
        return;
    }    else if ([savedFiles count] == 0) {
        self.mp3FileArray = mp3FileNames;
    }    else    {
        
        for (NSString *downFile in mp3FileNames) {
//            int thenumber =1*100+beacon.mediaID;
//            NSString *downFile = [ NSString stringWithFormat:@"%04d%@", thenumber,@".mp3"];
            NSLog(downFile);
            
            BOOL flag = false;
            
            for (Mp3File *savedFile in savedFiles) {
                
 
                
                if ([downFile isEqualToString:savedFile.fileName]) {
                    flag = true;
                    break;
                }
            }
            
            if (flag) {
                continue;
            }        else        {
                [self.mp3FileArray addObject:downFile];
            }
        }
    }
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    if([self.mp3FileArray count] != 0){
        [self downloadMp3File:(NSString*)self.mp3FileArray[0]];
    }else{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
        [self gotoNextVC];
    }
}

- (void)downloadMp3File:(NSString *) filename {
    
//    int thenumber =1*100+mediaid;
//    NSString *filename = [ NSString stringWithFormat:@"%04d%@", thenumber,@".mp3"];
    NSString *urlString = [NSString stringWithFormat:@"%@%@",BASE_URL, filename];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
    
    NSString *fileName = [urlString lastPathComponent];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Successfully downloaded file to %@", path);
        NSFileManager *fileManager = [NSFileManager defaultManager];

        if ([fileManager fileExistsAtPath:path]) { // yes
                NSLog(@"%@は既に存在しています", path);
        } else {
                NSLog(@"%@は存在していません", path);
        }
        [[[DataManager sharedManager] mp3Files] addObject:[[Mp3File alloc] initWith:fileName filePath:path]];
        
        [self.mp3FileArray removeObjectAtIndex:0];
        
        if ([self.mp3FileArray count] == 0){
            // Finish Downloading and Goto Main VC
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            NSLog(urlString);
            [self gotoNextVC];
        }        else        {
            [self downloadMp3File:(NSString*)self.mp3FileArray[0]];
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        
        if ([self.mp3FileArray count] == 0) {
            // Finish Downloading and Goto Main VC
            [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
            
            [self gotoNextVC];
        }     else     {
            [self.mp3FileArray removeObjectAtIndex:0];
            if ([self.mp3FileArray count] == 0) {
                [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
                [self gotoNextVC];
                
            }else{
                [self downloadMp3File:(NSString*)self.mp3FileArray[0]];
            }
        }
    }];
    
    [operation start];
}


#pragma mark-
#pragma mark Navigation Methods
-(void)gotoNextVC{
    //    return ;
    [[DataManager sharedManager] saveManager];
    
    NSMutableString *projectURL = [NSMutableString stringWithString:HOME_URL];
    //            [ projectURL appendString:@"/"];
    NSLog(self.project_name);
    [projectURL appendString:@"/"];
    [projectURL appendString:self.project_name];
    [projectURL appendString:@"/slider.html#instructions"];
    if([[DataManager sharedManager] onsite]){
        [projectURL appendString:@"?onsite=1"];
    }
    NSLog(projectURL);
    NSString *oururl = [NSString stringWithFormat:@"%@",projectURL];
    NSLog(oururl);
    
    //    NSURL *url = [NSURL URLWithString: @"http://www.google.com"];
    NSURL *url = [NSURL URLWithString: oururl];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    //    [self.webView stopLoading];
    
    [self.webView loadRequest:request];
    //    [self.webView stopLoading];
    
    NSLog(@"and it is done");
    
    
}


#pragma mark - Location Manager
- (void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    NSLog(@"mark 3 location manager called.");
    if(beacons ==nil){
        NSLog(@"beacons are nil but didRange called");
    }else{
        NSLog(@"beacons are NOT nil and didRange called");
        
        
        if([beacons count] == 0) { return; }
        NSLog(@"beacons count is not 0");
        NSLog(@"%d",[beacons count]);
        if([[DataManager sharedManager] beaconID]==nil){
            NSLog(@"and beacon id is null");
        }
        NSLog(@"%l",[[[DataManager sharedManager] beaconID] count]);
        
        CLBeacon *beacon = [ViewController getBeacon:beacons beaconID: [[DataManager sharedManager] beaconID]];
        if(beacon!=nil){
            [[DataManager sharedManager] setOnsite:TRUE];
            NSLog(@"mark 5 beacon in the ids found. set on site. ");
        }
        
    }
    
    
}


@end