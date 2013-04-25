/* Controller */

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
@interface Controller : NSObject
{
    IBOutlet id mainWindow;
    IBOutlet id activateButton;
    IBOutlet id helpWindow;
    IBOutlet id processView;   // NSMutableArray *processArray;
    NSFileManager *fm;
    NSTimer *timer;
    IBOutlet NSUserDefaultsController *udController;
    NSString *buttonTitle;

    
}
@property (retain) NSString *buttonTitle;
-(void)launchAppAtPath:(NSString *)path;
-(void)showHelp:(id)sender;
-(void)windowHotKeyPressed:(id)sender;
-(IBAction)donate:(id)sender;
-(IBAction)checkBoxSelected:(id)sender;
-(int)idleSeconds;
-(void)activateScreenSaver:(id)sender;
- (void)sleepNotifications;

@end
