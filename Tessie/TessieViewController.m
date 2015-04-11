//
//  RBLViewController.m
//  Tessie
//
//  Created by tesla plus on 03/28/2015.
//  Copyright (c) 2015 Tesla Plus.  All rights reserved.
//

#import "TessieViewController.h"
#import "TessieCommandTableViewCell.h"

#define TITLE_STR @"title"
#define COMMANDS_STR @"commands"

@interface TessieViewController ()
{
    NSMutableArray *tableData;
    NSMutableArray *commandPhrases;
    NSArray * cmdReset;
    NSArray * cmdBottom;
    NSArray * cmdTop;
}

@end

@implementation TessieViewController


- (void)viewDidLoad
{
    [super viewDidLoad];

    // reset sequence to move mouse the the top left and click, to close any open dialogs
    cmdReset = [NSArray arrayWithObjects:
                @"l127", @"l127", @"l127", @"l127", @"l127", @"l127", @"l127", @"l127",
                @"u127", @"u127", @"u127", @"u127", @"u127", @"u127", @"u127", @"u127",  @"u127", @"u127",
                @"c", @"w200", nil];

    cmdBottom = [NSArray arrayWithObjects:
                 @"d127", @"d127", @"d127", @"d127", @"d127", @"d127", @"d127", @"d127", @"d127", @"d127",
                 nil];

    cmdTop = [NSArray arrayWithObjects:
              @"u127", @"u127", @"u127", @"u127", @"u127", @"u127", @"u127", @"u127",  @"u127", @"u127",
            nil];


    tableData = [NSMutableArray array];

    activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = barButton;
    self.navigationItem.hidesBackButton = NO;

    bleShield = [[BLE alloc] init];
    [bleShield controlSetup];
    bleShield.delegate = self;

    self.fliteController = [[OEFliteController alloc] init];
    self.slt = [[Slt alloc] init];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, .5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self connectToTesla];
    });
}


-(void) connectionTimer:(NSTimer *)timer
{
    // TODO: Let user select BLE device or at list confirm
    if(bleShield.peripherals.count > 0)
    {
        [bleShield connectPeripheral:[bleShield.peripherals objectAtIndex:0]];
    }
    else
    {
        [activityIndicator stopAnimating];
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
}

- (void)connectToTesla
{
    if (bleShield.activePeripheral && bleShield.activePeripheral.state == CBPeripheralStateConnected)
    {
        [[bleShield CM] cancelPeripheralConnection:[bleShield activePeripheral]];
        return;
    }

    if (bleShield.peripherals) bleShield.peripherals = nil;

    [bleShield findBLEPeripherals:3];

    [NSTimer scheduledTimerWithTimeInterval:(float)3.0 target:self selector:@selector(connectionTimer:) userInfo:nil repeats:NO];

    [activityIndicator startAnimating];
    self.navigationItem.leftBarButtonItem.enabled = NO;
}

- (IBAction)BLEShieldScan:(id)sender
{
    [self connectToTesla];
}

NSTimer *rssiTimer;

-(void) readRSSITimer:(NSTimer *)timer
{
    [bleShield readRSSI];
}

- (void) bleDidDisconnect
{
    NSLog(@"bleDidDisconnect");
    [tableData  removeAllObjects];
    [_tableView reloadData];

    [self.navigationItem.leftBarButtonItem setTitle:@"Connect"];
    [activityIndicator stopAnimating];
    self.navigationItem.leftBarButtonItem.enabled = YES;

    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

// load commands from json file
-(void) initCommands
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"commands" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];

    //parse command data
    NSError* error;
    NSDictionary* commands = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    commandPhrases = [NSMutableArray arrayWithObjects: nil];

    for (NSDictionary * command in commands) {
        NSString * title = [command objectForKey:@"title"];
        NSLog(@"Adding Command: %@", title);
        [commandPhrases addObject:[title uppercaseString]];
        [tableData addObject:command];
    }

    [_tableView setContentOffset:CGPointMake(0, CGFLOAT_MAX)];
    [_tableView reloadData];

    OELanguageModelGenerator *lmGenerator = [[OELanguageModelGenerator alloc] init];


    NSString *name = @"TeslaCommands";
    NSError *err = [lmGenerator generateLanguageModelFromArray:commandPhrases withFilesNamed:name forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]]; // Change "AcousticModelEnglish" to "AcousticModelSpanish" to create a Spanish language model instead of an English one.

    if(err == nil) {

        lmPath = [lmGenerator pathToSuccessfullyGeneratedLanguageModelWithRequestedName:@"TeslaCommands"];
        dicPath = [lmGenerator pathToSuccessfullyGeneratedDictionaryWithRequestedName:@"TeslaCommands"];

    } else {
        NSLog(@"Error: %@",[err localizedDescription]);
    }

    self.openEarsEventsObserver = [[OEEventsObserver alloc] init];
    [self.openEarsEventsObserver setDelegate:self];

}

-(void) bleDidConnect
{
    [activityIndicator stopAnimating];
    [self initCommands];
    self.navigationItem.leftBarButtonItem.enabled = YES;
    self.voiceButton.enabled = YES;
    [self.navigationItem.leftBarButtonItem setTitle:@"Disconnect"];

    NSLog(@"bleDidConnect");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // TODO: dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *identifier = @"command_cell";
    TessieCommandTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    NSString *title = [dict objectForKey:TITLE_STR];
    cell.text.text = title;
    cell.text.textAlignment = NSTextAlignmentLeft;
    return cell;
}
- (IBAction)btnVoiceDown:(UIButton *)sender {
    [self startListening];
}

-(void) startListening {
    if ([[OEPocketsphinxController sharedInstance] isListening]) {
        return;
    }

    self.voiceButton.enabled = FALSE;

    [[OEPocketsphinxController sharedInstance] setActive:TRUE error:nil];
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [tableData count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSDictionary *dict = [tableData objectAtIndex:indexPath.row];
    [self sendCommand:dict];
}

-(void) bleDidReceiveData:(unsigned char *)data length:(int)length
{
    NSData *d = [NSData dataWithBytes:data length:length];
    NSString *s = [[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding];
    NSLog(@"received: %@", s);
}

- (void) sendCommand:(NSDictionary *) command {
    NSString * commandTitle = [command objectForKey:TITLE_STR];
    NSArray *commands = [command objectForKey:COMMANDS_STR];
    NSLog(@"Sending Command: \"%@\"", commandTitle);
    // TODO: Generalize / add "confirmation" to commands.json
    NSString * confirmation = [commandTitle stringByReplacingOccurrencesOfString:@"Show" withString:@"Showing"];
    [self.fliteController say:confirmation withVoice:self.slt];
    [self bleSendCommands:commands];
}

// Send (composite) command to car
-(void)bleSendCommands:(NSArray*) commands
{
    dispatch_async(dispatch_get_global_queue( 0, 0), ^(void){
        for (NSString * command in commands) {
            // todo: clean this up, encapsulate if possible.
            if ([@"reset" isEqualToString:command]) {
                for (NSString * cmdString in cmdReset) {
                    [self bleSendCommand:cmdString];
                }
            } else if ([@"top" isEqualToString:command]) {
                for (NSString * cmdString in cmdTop) {
                    [self bleSendCommand:cmdString];
                }
            } else if ([@"bottom" isEqualToString:command]) {
                for (NSString * cmdString in cmdBottom) {
                    [self bleSendCommand:cmdString];
                }
            } else {
                [self bleSendCommand:command];
            }
            // hack
            [NSThread sleepForTimeInterval:.05];
        }
    });
}


// Send (atomic) command to car
-(void)bleSendCommand:(NSString*) command
{
    command = [NSString stringWithFormat:@"%c%@%c", '#', command, '$'];

    NSData *d = [command dataUsingEncoding:NSUTF8StringEncoding];
    if (bleShield.activePeripheral.state == CBPeripheralStateConnected) {
        [bleShield write:d];
    }
}

- (void) pocketsphinxDidReceiveHypothesis:(NSString *)hypothesis recognitionScore:(NSString *)recognitionScore utteranceID:(NSString *)utteranceID {

    NSLog(@"Heard speech: \"%@\", score: %@, id: %@", hypothesis, recognitionScore, utteranceID);

    [commandPhrases enumerateObjectsUsingBlock:^(id phrase, NSUInteger idx, BOOL *stop)
     {
         NSRange range = [hypothesis rangeOfString:phrase];
         if (range.location != NSNotFound) {
             NSDictionary *dict = [tableData objectAtIndex:idx];
             [self sendCommand:dict];
             [[OEPocketsphinxController sharedInstance] stopListening];
             self.voiceButton.enabled = YES;
         }
     }];
}

- (void) pocketsphinxDidStartListening {
    NSLog(@"Voice: is now listening.");
}

- (void) pocketsphinxDidDetectSpeech {
    NSLog(@"Voice: has detected speech.");
}

- (void) pocketsphinxDidDetectFinishedSpeech {
    NSLog(@"Voice: has detected a period of silence, concluding an utterance.");
}

- (void) pocketsphinxDidStopListening {
    NSLog(@"Voice: has stopped listening.");
}

- (void) pocketsphinxDidSuspendRecognition {
    NSLog(@"Voice: has suspended recognition.");
}

- (void) pocketsphinxDidResumeRecognition {
    NSLog(@"Voice: has resumed recognition.");
}

- (void) pocketsphinxDidChangeLanguageModelToFile:(NSString *)newLanguageModelPathAsString andDictionary:(NSString *)newDictionaryPathAsString {
    NSLog(@"Voice: is now using the following language model: \n%@ and the following dictionary: %@",newLanguageModelPathAsString,newDictionaryPathAsString);
}

- (void) pocketSphinxContinuousSetupDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening setup wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) pocketSphinxContinuousTeardownDidFailWithReason:(NSString *)reasonForFailure {
    NSLog(@"Listening teardown wasn't successful and returned the failure reason: %@", reasonForFailure);
}

- (void) testRecognitionCompleted {
    NSLog(@"A test file that was submitted for recognition is now complete.");
}

@end
