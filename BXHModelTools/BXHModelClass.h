//
//  BXHModelClass.h
//  BXHModelTools
//
//  Created by 步晓虎 on 2017/12/26.
//  Copyright © 2017年 步晓虎. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kStringFormate(formate,...) [NSString stringWithFormat:formate,__VA_ARGS__]
#define kPropertyNum(name) kStringFormate(@"@property (nonatomic, strong) NSNumber *%@;\n\n",name)
#define kPropertyStr(name) kStringFormate(@"@property (nonatomic, copy) NSString *%@;\n\n",name)
#define kPropertyAry(name) kStringFormate(@"@property (nonatomic, strong) NSArray *%@;\n\n",name)
#define kPropertyAryCls(clsName,name) kStringFormate(@"@property (nonatomic, strong) NSArray <%@ *>*%@;\n\n",clsName,name)
#define kPropertyDict(name) kStringFormate(@"@property (nonatomic, strong) NSDictionary *%@;\n\n",name)
#define kPropertyDictCls(clsName,name) kStringFormate(@"@property (nonatomic, strong) %@ *%@;\n\n",clsName,name)

#define kHeaderCls(clsName) kStringFormate(@"@interface %@ : NSObject",clsName)
#define kHeaderClsCopying(clsName) kStringFormate(@"@interface %@ : NSObject <NSCopying>",clsName)
#define kHeaderClsCoding(clsName) kStringFormate(@"@interface %@ : NSObject <NSCoding>",clsName)
#define kHeaderClsCodingAndCopying(clsName) kStringFormate(@"@interface %@ : NSObject <NSCoding,NSCopying>",clsName)

#define kDetaultClsName @"BXHModel"
#define kImplementationCls(clsName) kStringFormate(@"@implementation %@",clsName)

#define kFileEnd @"@end"

#define kMethodCodeInitPre @"- (instancetype)initWithCoder:(NSCoder *)aDecoder\n{\n    if (self = [super init])\n    {"
#define KMethodDecode(propertyName) kStringFormate(@"\n        _%@ = [aDecoder decodeObjectForKey:@\"%@\"];",propertyName,propertyName)
#define kMethodCodeInitTri @"\n    }\n    return self;\n}\n"

#define kMethodEncodePre @"- (void)encodeWithCoder:(NSCoder *)aCoder\n{"
#define kMethodEncode(propertyName) kStringFormate(@"\n    [aCoder encodeObject:_%@ forKey:@\"%@\"];",propertyName,propertyName)
#define kMethodEncodeTri @"\n}\n"

#define kMethodCopyPre(clsName) kStringFormate(@"- (id)copyWithZone:(NSZone *)zone\n{\n    %@ *model = [[%@ allocWithZone:zone] init];",clsName,clsName)
#define kMethodCopy(propertyName) kStringFormate(@"\n    model.%@ = self.%@;",propertyName,propertyName)
#define kMethodCopyTri @"\n    return model;\n}\n"

#define kMethodJSONToModelPre @"- (id)bxh_JsonSerializeWithSerializeArray:(NSArray *)array andPropertyName:(NSString *)name\n{"
#define KMethodJSONToModel(clsName,propertyName) kStringFormate(@"\n    if ([name isEqualToString:@\"%@\"])\n    {\n        return [%@ bxh_modelArySerializeWithAry:array];\n    }",propertyName,clsName)
#define kMethodJSONToModelTri @"\n    return nil;\n}\n"

#define kMethodModelToJSONPre @"- (NSArray *)bxh_JsonSerizlizeAryWithModels:(NSArray *)modelAry andPropertyName:(NSString *)name\n{"
#define KMethodModelToJSON(clsName,propertyName) kStringFormate(@"\n    if ([name isEqualToString:@\"%@\"])\n    {\n        return [%@ bxh_DeserializeToAryWithModelAry:modelAry];\n    }",propertyName,clsName)
#define kMethodModelToJSONTri @"\n    return @[];\n}\n"

#define kFileHeader(clsName,dateStr) kStringFormate(@"//\n//  %@\n//  BXHModelTools.h\n//\n//  Created by 步晓虎 on %@.\n//  版权所有>>>>步晓虎.\n//\n\n#import <Foundation/Foundation.h>\n\n",clsName,dateStr)

#define kFileImplementation(clsName,dateStr) kStringFormate(@"//\n//  %@\n//  BXHModelTools.m\n//\n//  Created by 步晓虎 on %@.\n//  版权所有>>>>步晓虎.\n//\n\n#import \"%@.h\"\n\n",clsName,dateStr,clsName)



typedef NS_ENUM(NSInteger, BXHModelType)
{
    BXHModelTypeRoot,
    BXHModelTypeSub
};

typedef NS_ENUM(NSInteger, BXHModelClsType)
{
    BXHModelClsTypeNum,
    BXHModelClsTypeStr,
    BXHModelClsTypeDic,
    BXHModelClsTypeAry,
    BXHModelClsTypeNull
};

typedef NS_ENUM(NSInteger, BXHModelCreatStatue)
{
    BXHModelCreatRootObjError,
    BXHModelCreaPropertyClsNeedInputError,
    BXHModelCreatSuccess
};

@class BXHModelClass;

typedef id (^BXHModelCreatCallBack)(BXHModelCreatStatue error,id obj);
@interface BXHModelProperty : NSObject

@property (nonatomic, copy, readonly) NSString *propertyName;

@property (nonatomic, copy, readonly) NSString *propertyClsName;

@property (nonatomic, assign, readonly) BXHModelClsType clsType;

@property (nonatomic, copy, readonly) NSString *propertyStr; //拼装

@property (nonatomic, copy, readonly) id <NSCopying>propertyObj;

@property (nonatomic, strong, readonly) BXHModelClass *propertModel;

@end

@interface BXHModelClass : NSObject

@property (nonatomic, copy) NSString *clsName; //default kDetaultClsName

@property (nonatomic, assign) BOOL needCopying;

@property (nonatomic, assign) BOOL needCodeing;

@property (nonatomic, assign, readonly) BXHModelType modelType;

@property (nonatomic, copy, readonly) NSString *headerStr;

@property (nonatomic, copy, readonly) NSString *implementationStr;

@property (nonatomic, copy, readonly) NSString *methodStr;

@property (nonatomic, strong, readonly) NSMutableArray <BXHModelProperty *>*propertys;

@property (nonatomic, copy, readonly) id rootObject;

- (instancetype)initWithRootObject:(id)rootObject andModelType:(BXHModelType)modelType andCreatCallBack:(BXHModelCreatCallBack)callBack;

- (void)startAnalysis;

@end

@interface BXHModelClass (BXHFileString)

- (NSString *)fileHeaderString;

- (NSString *)fileImplementationString;

@end

