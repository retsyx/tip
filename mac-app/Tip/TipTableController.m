//
//  TipTableView.m
//  tip
//
//  Created by Tanin Na Nakorn on 12/29/19.
//  Copyright © 2019 Tanin Na Nakorn. All rights reserved.
//

#import "TipTableController.h"
#import "TipTableView.h"
#import "TipItemTextField.h"
#import "VeritcallyAlignNSTextFieldCell.h"
#include <stdlib.h>
#import "TipNoticeView.h"

@implementation TipTableController

- (instancetype)init {
    if (self = [super init]) {
        self.view = [[NSView alloc] init];

        _noticeView = [[TipNoticeView alloc] initWithFrame:CGRectMake(0, 0, 350, 0)];
        _noticeView.hidden = YES;
        [self.view addSubview:_noticeView];
        
        _table = [[TipTableView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _table.focusRingType = NSFocusRingTypeNone;
        _table.dataSource = self;
        _table.delegate = self;
        _table.cell.bordered = NO;
        _table.allowsMultipleSelection = NO;
        _table.action = @selector(clickRow:);
        _table.cell.bezeled = NO;
        _table.enterPressedAction = @selector(pressEnter);
        _table.target = self;
        _table.intercellSpacing = CGSizeMake(0, 0);
        _table.hidden = YES;
        
        _iconColumn = [[NSTableColumn alloc] initWithIdentifier:@"icon"];
        _iconColumn.width = 18;
        _textColumn = [[NSTableColumn alloc] initWithIdentifier:@"text"];
        _textColumn.width = 25;
        [_table addTableColumn:_iconColumn];
        [_table addTableColumn:_textColumn];
        [self.view addSubview:_table];
    }
    return self;
}

- (void) clickRow:(id)sender {
    [self performAction:_table.clickedRow];
}

- (void) pressEnter {
    if (_table.selectedRow >= 0) {
        [self performAction:_table.selectedRow];
    }
}

- (void) setError:(NSException*)error {
    _error = error;
    _items = nil;
    [self update];
}

- (void)setItems:(NSArray<TipItem *> *)items {
    _items = items;
    _error = nil;
    [self update];
    [_table reloadData];
}

- (void)update {
    if (_error) {
        _noticeView.hidden = NO;
        _table.hidden = YES;
        
        NSString *message = nil;
        TipNoticeViewAction action = TipNoticeViewActionNone;
        
        if ([_error.name isEqualToString:@"MalformedJsonException"]) {
            message = @"Malformed JSON returned from provider. Click to see logs in Console. You'll need to set the filter Process=Tip.";
            action = TipNoticeViewActionOpenConsole;
        } else if ([_error.name isEqualToString:@"ProviderNotExistException"]) {
            message = [NSString stringWithFormat:@"%@ doesn't exist. Please make a provider script. Click to see instruction.", [_error.userInfo objectForKey:@"provider"]];
            action = TipNoticeViewActionOpenProviderInstruction;
        } else if ([_error.name isEqualToString:@"ProviderNotExecutableException"]) {
            message = [NSString stringWithFormat:@"Provider isn't executable. Please chmod 755 %@", [_error.userInfo objectForKey:@"provider"]];
        } else {
            message = @"Error occurred. Click to see logs in Console. You'll need to set the filter Process=Tip.";
            action = TipNoticeViewActionOpenConsole;
        }
        
        [_noticeView updateWithMessage:message
                                  icon:0xf06a
                                action:action];
        
        self.preferredContentSize = _noticeView.frame.size;
    } else if (_items.count == 0) {
        _noticeView.hidden = NO;
        _table.hidden = YES;
        [_noticeView updateWithMessage:@"No tips. You can add tips through your provider script. Click to see the instruction."
                                  icon:0xf59a
                                action:TipNoticeViewActionOpenProviderInstruction];
        self.preferredContentSize = _noticeView.frame.size;
    } else {
        _noticeView.hidden = YES;
        _table.hidden = NO;
        
        NSTextField* textField = [self makeTextField];
        
        CGFloat textFieldWidth = 0;
        CGFloat height = 0;
        for (TipItem* item in _items) {
            textField.stringValue = item.label;
            textFieldWidth = MAX(textFieldWidth, textField.frame.size.width);
            height += textField.frame.size.height;
        }
        
        self.preferredContentSize = CGSizeMake(19 + textFieldWidth, height);
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _items.count;
}

- (void) performAction:(NSUInteger) row {
    TipItem* item = [_items objectAtIndex:row];
    NSTableRowView* rowView = [_table rowViewAtRow:row makeIfNecessary:false];
    
    
    if (item.type == TipItemTypeUrl) {
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:item.value]];
    } else {
        NSTextField* iconText = ((NSView*)[rowView viewAtColumn:0]).subviews.firstObject;
        
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
            context.duration = 0.1;
            iconText.animator.alphaValue = 0;
        }
        completionHandler:^{
            iconText.alphaValue = 1;
            iconText.stringValue = @"\uf46c";
        }];
        
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        [pasteboard setString:item.value forType:NSPasteboardTypeString];
    }
}

- (NSTextField*)makeTextField {
    NSTextField* textField = [[TipItemTextField alloc] initWithFrame:NSMakeRect(0, 0, 1000, 22)];
    textField.cell = [VeritcallyAlignNSTextFieldCell new];
    textField.editable = NO;
    textField.selectable = YES;
    textField.bezeled = NO;
    textField.drawsBackground = NO;
    textField.font = [NSFont fontWithName:@"RobotoMono-Regular" size:12];
    textField.lineBreakMode = NSLineBreakByTruncatingTail;
    return textField;
}

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 22;
}

- (nullable NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(nullable NSTableColumn *)tableColumn row:(NSInteger)row {
    NSView* result = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    TipItem* item = [_items objectAtIndex:row];
    
    if (!item) { return nil; }
    
    if (tableColumn == _iconColumn) {
        NSView* icon = (NSTextField*)result;
        if (icon == nil) {
            icon = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 18, 22)];
            
            NSTextField* iconText = [[NSTextField alloc] initWithFrame:NSMakeRect(2, 0, 16, 22)];
            iconText.cell = [VeritcallyAlignNSTextFieldCell new];
            iconText.cell.font = [NSFont fontWithName:@"Font Awesome 5 Free" size:12];
            iconText.editable = NO;
            iconText.selectable = NO;
            iconText.bezeled = NO;
            iconText.drawsBackground = NO;
                    
            [icon addSubview:iconText];
        }
        
        NSTextField* iconText = icon.subviews.firstObject;
        if (item.type == TipItemTypeUrl) {
            iconText.stringValue = @"\uf35d";
        } else {
            iconText.stringValue = @"\uf0c5";
        }
        
        return icon;
    } else if (tableColumn == _textColumn) {
        NSTextField* textField = (NSTextField*)result;
        if (textField == nil) {
            textField = [self makeTextField];
        }
        textField.stringValue = item.label;
        return textField;
    } else {
        @throw [NSException
                exceptionWithName:@"Exception"
                reason:[NSString stringWithFormat:@"Invalid column: %@", tableColumn.identifier]
                userInfo:nil];
    }
}

@end
