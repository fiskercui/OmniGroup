// Copyright 1997-2009, 2013 Omni Development, Inc. All rights reserved.
//
// This software may only be used and reproduced according to the
// terms in the file OmniSourceLicense.html, which should be
// distributed with this project and can also be found at
// <http://www.omnigroup.com/developer/sourcecode/sourcelicense/>.

#import <OmniAppKit/NSAlert-OAExtensions.h>

RCS_ID("$Id$")


@interface _OAAlertSheetCompletionHandlerRunner : OFObject
{
    NSAlert *_alert;
    OAAlertSheetCompletionHandler _completionHandler;
}
@end
@implementation _OAAlertSheetCompletionHandlerRunner
- initWithAlert:(NSAlert *)alert completionHandler:(OAAlertSheetCompletionHandler)completionHandler;
{
    if (!(self = [super init]))
        return nil;
    
    _alert = [alert retain];
    _completionHandler = [completionHandler copy];
    return self;
}
- (void)dealloc;
{
    [_alert release];
    [_completionHandler release];
    [super dealloc];
}

- (void)startOnWindow:(NSWindow *)parentWindow;
{
    // We have to live until the callback, but a -retain will annoy clang-sa.
    OBAnalyzerProofRetain(self);
    [_alert beginSheetModalForWindow:parentWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    OBPRECONDITION(alert == _alert);
    
    // Clean up the hidden -retain from -startOnWindow:, first and with -autorelease in case the block asplodes.
    OBAnalyzerProofAutorelease(self);
    
    if (_completionHandler)
        _completionHandler(_alert, returnCode);
}

@end

@implementation NSAlert (OAExtensions)

- (void)oa_beginSheetModalForWindow:(NSWindow *)window completionHandler:(OAAlertSheetCompletionHandler)completionHandler;
{
    _OAAlertSheetCompletionHandlerRunner *runner = [[_OAAlertSheetCompletionHandlerRunner alloc] initWithAlert:self completionHandler:completionHandler];
    [runner startOnWindow:window];
    [runner release];
}

@end



void OABeginAlertSheet(NSString *title, NSString *defaultButton, NSString *alternateButton, NSString *otherButton, NSWindow *docWindow, OAAlertSheetCompletionHandler completionHandler, NSString *msgFormat, ...)
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:title];
    
    if (msgFormat) {
        va_list args;
        va_start(args, msgFormat);
        NSString *informationalText = [[NSString alloc] initWithFormat:msgFormat arguments:args];
        va_end(args);
        
        [alert setInformativeText:informationalText];
        [informationalText release];
    }
    
    if (defaultButton)
        [alert addButtonWithTitle:defaultButton];
    if (alternateButton)
        [alert addButtonWithTitle:alternateButton];
    if (otherButton)
        [alert addButtonWithTitle:otherButton];
    
    [alert oa_beginSheetModalForWindow:docWindow completionHandler:completionHandler];
    [alert release]; // retained by the runner while the sheet is up
}

