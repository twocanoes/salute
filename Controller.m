#import "Controller.h"
#include <unistd.h>
#include <IOKit/IOKitLib.h>

EventHotKeyRef gMyHotKeyRef;
EventHotKeyID gMyHotKeyID;
EventHandlerUPP gAppHotKeyFunction;


id me;
@implementation Controller
@synthesize buttonTitle;
pascal OSStatus TCHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData)
{
    [me windowHotKeyPressed:me];
    return noErr;
    
}
- init
{
    if (self = [super init]) {
        NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithContentsOfFile:[NSBundle pathForResource:@"defaults" ofType:@"plist" inDirectory:[[NSBundle mainBundle] resourcePath]]];
        [[NSUserDefaults standardUserDefaults] registerDefaults:dict];
        
    }
    me=self;
    return self;
}


-(void)checkIdleTimer:(NSNotification *)notification{

    BOOL switchWhenIdle=[[NSUserDefaults standardUserDefaults] boolForKey:@"switchWhenIdle"];
    BOOL switchToLoginWindow=[[NSUserDefaults standardUserDefaults] boolForKey:@"switchToLoginWindow"];
    if (switchToLoginWindow && switchWhenIdle && ([self idleSeconds]>[[NSUserDefaults standardUserDefaults] integerForKey:@"idleTime"]) ) [self activateScreenSaver:self];
                 
    
    
}
-(void)awakeFromNib{


    timer=[NSTimer scheduledTimerWithTimeInterval:[[NSDate dateWithTimeIntervalSinceNow:5] timeIntervalSinceNow]
                                   target:self selector:@selector(checkIdleTimer:) userInfo:nil repeats:YES];
    [timer retain];
    [self sleepNotifications];
    fm=[NSFileManager defaultManager];    
    EventTypeSpec eventType;
    gAppHotKeyFunction = NewEventHandlerUPP(TCHotKeyHandler);
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(gAppHotKeyFunction,1,&eventType,NULL,NULL);
    gMyHotKeyID.signature='tcs1';
    gMyHotKeyID.id=1;
    
    RegisterEventHotKey(51, cmdKey|controlKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);

    gMyHotKeyID.signature='tcs2';
    gMyHotKeyID.id=2;
    
    RegisterEventHotKey(117, cmdKey|controlKey, gMyHotKeyID, GetApplicationEventTarget(), 0, &gMyHotKeyRef);
        
    NSSize screenSize=[[NSScreen mainScreen] frame].size;
    [mainWindow setFrameOrigin:NSMakePoint(screenSize.width/2-[mainWindow frame].size.width/2,screenSize.height/2)];

    if([[udController defaults] boolForKey:@"firstLaunch"]==YES) {
        [NSApp activateIgnoringOtherApps:YES];
        [mainWindow makeKeyAndOrderFront:self];
        [self showHelp:nil];
        [[udController defaults] setBool:NO forKey:@"firstLaunch"];
    }
    [self checkBoxSelected:self];

}


-(IBAction)checkBoxSelected:(id)sender{
    if ([[udController defaults] boolForKey:@"switchToLoginWindow"]) [self setButtonTitle:@"Login Window"];
    else  [self setButtonTitle:@"Screen Saver"];
    
    [udController save:self];
}
-(void)windowHotKeyPressed:(id)sender{

    [NSApp activateIgnoringOtherApps:YES];
    [mainWindow makeKeyAndOrderFront:self];
}


-(void)activateScreenSaver:(id)sender{
	[mainWindow orderOut:self];
    
    if (![[udController defaults] boolForKey:@"switchToLoginWindow"]) {

        [self launchAppAtPath:@"/System//Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app"];
    }

/*	ScreenSaverController* ss=[[ScreenSaverController alloc] init];
	[ss screenSaverStartNow];
	[ss release];
 */
    else 
    [NSTask launchedTaskWithLaunchPath:@"/System/Library/CoreServices/Menu Extras/User.menu/Contents/Resources/CGSession"
                             arguments:[NSArray arrayWithObject:@"-suspend"]];
  
}


-(void)startActivityViewer:(id)sender{

    NSString *launchPath=[[udController values] valueForKey:@"activitymonitor"];
    [self launchAppAtPath:launchPath];
}

-(void)launchAppAtPath:(NSString *)path{
    
    if ([fm fileExistsAtPath:path]) {
		[[NSWorkspace sharedWorkspace] launchApplication:path];
		[mainWindow orderOut:self];
    }
}
    
-(void)startTerminal:(id)sender{
    NSString *launchPath=[[udController defaults] valueForKey:@"terminal"];
    [self launchAppAtPath:launchPath];
}
-(void)showHelp:(id)sender{
    [NSApp beginSheet:helpWindow modalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}
-(void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo{
    [sheet orderOut:self];
}

-(void)helpDone:(id)sender{
    [NSApp endSheet: helpWindow];
    
}
-(IBAction)donate:(id)sender{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.twocanoes.com/donate.html"]];
}
- (void) receiveSleepNote: (NSNotification*) note
{
    BOOL switchToLoginWindow=[[NSUserDefaults standardUserDefaults] boolForKey:@"switchToLoginWindow"];
    BOOL switchWhenIdle=[[NSUserDefaults standardUserDefaults] boolForKey:@"switchWhenIdle"];
    if (switchToLoginWindow && switchWhenIdle) [self activateScreenSaver:self];
    
}

- (void) receiveWakeNote: (NSNotification*) note
{

}

- (void) sleepNotifications
{
    //These notifications are filed on NSWorkspace's notification center, not the default notification center. 
    //  You will not receive sleep/wake notifications if you file with the default notification center.
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
                                                           selector: @selector(receiveSleepNote:) name: NSWorkspaceWillSleepNotification object: NULL];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self 
                                                           selector: @selector(receiveWakeNote:) name: NSWorkspaceDidWakeNotification object: NULL];
}

-(int)idleSeconds{
    io_service_t    platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault,
                                                                 IOServiceMatching("IOHIDSystem"));
    int secs=0;
    if (platformExpert) {
        CFTypeRef serialNumberAsCFString =
        IORegistryEntryCreateCFProperty(platformExpert,
                                        CFSTR("HIDIdleTime"),
                                        kCFAllocatorDefault, 0);
        if (serialNumberAsCFString) {
            
            long long out;
            
            CFNumberGetValue(serialNumberAsCFString, kCFNumberSInt64Type, &out);
            secs=out/1000000000;
            
        }
        
        IOObjectRelease(platformExpert);
        CFRelease(serialNumberAsCFString);
    }

    return secs;
}


-(void)dealloc{
    [timer invalidate];
    [timer release];
    [super dealloc];
}
@end
