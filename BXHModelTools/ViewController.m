//
//  ViewController.m
//  BXHModelTools
//
//  Created by 步晓虎 on 2017/12/25.
//  Copyright © 2017年 步晓虎. All rights reserved.
//

#import "ViewController.h"
#import "BXHModelClass.h"

@interface ViewController ()

@property (unsafe_unretained) IBOutlet NSTextView *InputTextView;
@property (unsafe_unretained) IBOutlet NSTextView *implementationTextView;
@property (unsafe_unretained) IBOutlet NSTextView *headerTextView;
@property (weak) IBOutlet NSTextField *modelNameTextFiled;
@property (weak) IBOutlet NSButton *codingBtn;
@property (weak) IBOutlet NSButton *copyingBtn;

@property (nonatomic, strong) BXHModelClass *cls;

@end

@implementation ViewController

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"BXHModel";
    self.codingBtn.enabled = NO;
    self.copyingBtn.enabled = NO;
    self.InputTextView.automaticQuoteSubstitutionEnabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFiledTextChanged:) name:NSControlTextDidChangeNotification object:nil];
    // Do any additional setup after loading the view.
}

- (IBAction)needCodingAction:(NSButton *)sender
{
    self.cls.needCodeing = sender.state == 1;
    self.headerTextView.string = [self.cls fileHeaderString];
    self.implementationTextView.string = [self.cls fileImplementationString];
}

- (IBAction)needCopyAction:(NSButton *)sender
{
    self.cls.needCopying = sender.state == 1;
    self.headerTextView.string = [self.cls fileHeaderString];
    self.implementationTextView.string = [self.cls fileImplementationString];
}

- (IBAction)analysisStartAction:(id)sender
{
    self.codingBtn.state = 0;
    self.copyingBtn.enabled = 0;
    self.headerTextView.string = @"";
    self.implementationTextView.string = @"";
    
    NSTextView *textView = self.InputTextView;
    id jsonObject = [self _toJsonObj:textView.string];
    if (jsonObject)
    {
        textView.string = [self _JSONFormate:jsonObject];
    }
    __weak typeof(self) weakSelf = self;
    self.cls = [[BXHModelClass alloc] initWithRootObject:jsonObject andModelType:BXHModelTypeRoot andCreatCallBack:^id(BXHModelCreatStatue error, id obj) {
        __strong typeof(weakSelf) strongSelf = self;
        strongSelf.codingBtn.enabled = NO;
        strongSelf.copyingBtn.enabled = NO;
        switch (error)
        {
            case BXHModelCreatRootObjError:
            {
                NSAlert *alert = [NSAlert new];
                alert.alertStyle = NSAlertStyleCritical;
                alert.messageText = @"提示";
                alert.informativeText = @"JSONStr输入有误";
                [alert addButtonWithTitle:@"确定"];
                [alert runModal];
                return nil;
            }
            case BXHModelCreaPropertyClsNeedInputError:
            {
                NSAlert *alert = [NSAlert new];
                alert.alertStyle = NSAlertStyleCritical;
                NSTextField *modelNameTextFiled = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 300, 30)];
                alert.messageText = obj;
                alert.accessoryView = modelNameTextFiled;
                [alert addButtonWithTitle:@"确定"];
                [alert runModal];
                return modelNameTextFiled.stringValue;
            }
            case BXHModelCreatSuccess:
            default:
            {
                strongSelf.codingBtn.enabled = YES;
                strongSelf.copyingBtn.enabled = YES;
                strongSelf.headerTextView.string = [strongSelf.cls fileHeaderString];
                strongSelf.implementationTextView.string = [strongSelf.cls fileImplementationString];
                return nil;
            }
        }
    }];
    self.cls.clsName = self.modelNameTextFiled.stringValue;
    [self.cls startAnalysis];
}

- (IBAction)creatFileAction:(NSButton *)sender
{
    if (self.headerTextView.string.length > 0 && self.implementationTextView.string.length > 0)
    {
        NSString *filePath = [self _filepath];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:filePath])
        {
            [fm createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSString *headerPath = [NSString stringWithFormat:@"%@/%@.h",filePath,self.cls.clsName];
        NSString *implementationPath = [NSString stringWithFormat:@"%@/%@.m",filePath,self.cls.clsName];
        if ([fm fileExistsAtPath:headerPath])
        {
            [fm removeItemAtPath:headerPath error:NULL];
        }
        NSData *data = [self.headerTextView.string dataUsingEncoding:NSUTF8StringEncoding];
        [fm createFileAtPath:headerPath contents:data attributes:nil];
        if ([fm fileExistsAtPath:implementationPath])
        {
            [fm removeItemAtPath:implementationPath error:NULL];
        }
        data = [self.implementationTextView.string dataUsingEncoding:NSUTF8StringEncoding];
        [fm createFileAtPath:implementationPath contents:data attributes:nil];
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"提示";
        alert.informativeText = @"文件生成成功请去文稿查看";
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
        [[NSWorkspace sharedWorkspace] selectFile:nil inFileViewerRootedAtPath:filePath];
    }
    else
    {
        NSAlert *alert = [NSAlert new];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"提示";
        alert.informativeText = @"生成错误";
        [alert addButtonWithTitle:@"确定"];
        [alert runModal];
    }
}

- (id)_toJsonObj:(NSString *)jsonStr
{
    NSError *parseError = nil;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&parseError];
    return jsonObject;
}

- (NSString *)_JSONFormate:(id)jsonObj
{
    return [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonObj options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
}

- (NSString *)_filepath
{
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    return [NSString stringWithFormat:@"%@/BXHModelTools",documentPath];
}

#pragma mark - textViewDelegate
- (void)textFiledTextChanged:(NSNotification *)notification
{
    if([notification.object isEqual:self.modelNameTextFiled])
    {
        self.cls.clsName = self.modelNameTextFiled.stringValue;
        self.headerTextView.string = [self.cls fileHeaderString];
        self.implementationTextView.string = [self.cls fileImplementationString];
    }
}


@end
