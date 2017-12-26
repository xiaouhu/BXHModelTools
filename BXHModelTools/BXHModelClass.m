//
//  BXHModelClass.m
//  BXHModelTools
//
//  Created by 步晓虎 on 2017/12/26.
//  Copyright © 2017年 步晓虎. All rights reserved.
//

#import "BXHModelClass.h"

static inline BXHModelClsType clsObjectTypeDiscern(id obj)
{
    if ([obj isKindOfClass:[NSString class]])
    {
        return BXHModelClsTypeStr;
    }
    else if ([obj isKindOfClass:[NSNumber class]])
    {
        return BXHModelClsTypeNum;
    }
    else if ([obj isKindOfClass:[NSArray class]])
    {
        return BXHModelClsTypeAry;
    }
    else if ([obj isKindOfClass:[NSDictionary class]])
    {
        return BXHModelClsTypeDic;
    }
    else
    {
        return BXHModelClsTypeNull;
    }
}


typedef id (^BXHModelPropertyCreatBlock)(BXHModelCreatStatue statue, id obj);
@interface BXHModelProperty ()

@property (nonatomic, copy) BXHModelPropertyCreatBlock creatBlock;
- (instancetype)initWithPropertyName:(NSString *)propertyName andObj:(id)obj andBlock:(BXHModelPropertyCreatBlock)block;

@end

@implementation BXHModelProperty

- (instancetype)initWithPropertyName:(NSString *)propertyName andObj:(id)obj andBlock:(BXHModelPropertyCreatBlock)block
{
    if (self = [super init])
    {
        _propertyName = propertyName;
        _propertyObj = [obj copy];
        self.creatBlock = block;
        [self _discernPropertyObject];
    }
    return self;
}

- (void)_discernPropertyObject
{
    _clsType = clsObjectTypeDiscern(_propertyObj);
    switch (self.clsType)
    {
        case BXHModelClsTypeStr:
        case BXHModelClsTypeNull:
        {
            _propertyClsName = NSStringFromClass([NSString class]);
            _propertyStr = kPropertyStr(_propertyName);
        }
            break;
        case BXHModelClsTypeNum:
        {
            _propertyClsName = NSStringFromClass([NSNumber class]);
            _propertyStr = kPropertyNum(_propertyName);
        }
            break;
        case BXHModelClsTypeDic:
        {
            NSString *clsName = self.creatBlock(BXHModelCreaPropertyClsNeedInputError,_propertyName);
            if (clsName.length > 0)
            {
                _propertyClsName = clsName;
                __weak typeof(self) weakSelf = self;
                _propertModel = [[BXHModelClass alloc] initWithRootObject:_propertyObj andModelType:BXHModelTypeSub andCreatCallBack:^id(BXHModelCreatStatue error, id obj) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    return strongSelf.creatBlock(error, obj);
                }];
                _propertModel.clsName = _propertyClsName;
                [_propertModel startAnalysis];
                _propertyStr = kPropertyDictCls(_propertyClsName, _propertyName);
            }
            else
            {
                _propertyClsName = NSStringFromClass([NSDictionary class]);
                _propertyStr = kPropertyDict(_propertyName);
            }
        }
            break;
        case BXHModelClsTypeAry:
        default:
        {
            NSString *clsName = self.creatBlock(BXHModelCreaPropertyClsNeedInputError,_propertyName);
            if (clsName.length > 0)
            {
                _propertyClsName = clsName;
                
                NSArray *rootAry = (NSArray *)_propertyObj;
                if (rootAry.count == 0)
                {
                    _propertyClsName = NSStringFromClass([NSArray class]);
                    _propertyStr = kPropertyAry(_propertyName);
                    return;
                }
                __weak typeof(self) weakSelf = self;
                _propertModel = [[BXHModelClass alloc] initWithRootObject:[rootAry firstObject] andModelType:BXHModelTypeSub andCreatCallBack:^id(BXHModelCreatStatue error, id obj) {
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    return strongSelf.creatBlock(error, obj);
                }];
                _propertModel.clsName = _propertyClsName;
                [_propertModel startAnalysis];
                _propertyStr = kPropertyAryCls(_propertyClsName, _propertyName);
            }
            else
            {
                _propertyClsName = NSStringFromClass([NSArray class]);
                _propertyStr = kPropertyAry(_propertyName);
            }
        }
            break;
    }
}

@end

@interface BXHModelClass ()

@property (nonatomic, copy) BXHModelCreatCallBack callBack;

@end

@implementation BXHModelClass

- (instancetype)initWithRootObject:(id)rootObject andModelType:(BXHModelType)modelType andCreatCallBack:(BXHModelCreatCallBack)callBack
{
    if (self = [super init])
    {
        _rootObject = rootObject;
        _modelType = modelType;
        _rootObject = [rootObject copy];
        _propertys = [NSMutableArray array];
        _clsName = kDetaultClsName;
        self.callBack = callBack;
    }
    return self;
}

- (void)startAnalysis
{
    [self _discernRootObject];
}

- (void)_discernRootObject
{
    if (!_rootObject)
    {
        self.callBack(BXHModelCreatRootObjError, _rootObject);
        return;
    }
    BXHModelClsType clsType = clsObjectTypeDiscern(_rootObject);
    switch (clsType)
    {
        case BXHModelClsTypeStr:
        case BXHModelClsTypeNum:
        case BXHModelClsTypeNull:
        {
            self.callBack(BXHModelCreatRootObjError, _rootObject);
        }
            break;
        case BXHModelClsTypeDic:
        {
            [self _jsonDictToStr:_rootObject];
        }
            break;
        case BXHModelClsTypeAry:
        default:
        {
            NSArray *rootAry = (NSArray *)_rootObject;
            if (rootAry.count > 0)
            {
                [self _jsonDictToStr:[rootAry firstObject]];
            }
            else
            {
                self.callBack(BXHModelCreatRootObjError, _rootObject);
            }
        }
            break;
    }
}

- (void)_jsonDictToStr:(NSDictionary *)jsonDict
{
    __weak typeof(self) weakSelf = self;
    [jsonDict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BXHModelProperty *property = [[BXHModelProperty alloc] initWithPropertyName:key andObj:obj andBlock:^id (BXHModelCreatStatue statue, id obj) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            return strongSelf.callBack(statue,obj);
        }];
        [strongSelf -> _propertys addObject:property];
    }];
    self.callBack(BXHModelCreatSuccess, self);
}

#pragma mark - get
- (NSString *)headerStr
{
    if (self.needCodeing && self.needCopying)
    {
        return kHeaderClsCodingAndCopying(_clsName);
    }
    else if (self.needCopying)
    {
        return kHeaderClsCopying(_clsName);
    }
    else if (self.needCodeing)
    {
        return kHeaderClsCoding(_clsName);
    }
    return kHeaderCls(_clsName);
}

- (NSString *)implementationStr
{
    return kImplementationCls(_clsName);
}

- (NSString *)methodStr
{
    NSString *copyStr = @"";
    NSString *decoderStr = @"";
    NSString *encoderStr = @"";
    NSString *JSONToModel = @"";
    NSString *modelToJSON = @"";
    for (BXHModelProperty *property in self.propertys)
    {
        if(self.needCodeing)
        {
            decoderStr = [NSString stringWithFormat:@"%@%@",decoderStr,KMethodDecode(property.propertyName)];
            encoderStr = [NSString stringWithFormat:@"%@%@",encoderStr,kMethodEncode(property.propertyName)];
        }
        if (self.needCopying)
        {
            copyStr = [NSString stringWithFormat:@"%@%@",copyStr,kMethodCopy(property.propertyName)];
        }
        if (property.propertModel && property.clsType == BXHModelClsTypeAry)
        {
            JSONToModel = [NSString stringWithFormat:@"%@%@",JSONToModel,KMethodJSONToModel(property.propertyClsName, property.propertyName)];
            modelToJSON = [NSString stringWithFormat:@"%@%@",modelToJSON,KMethodModelToJSON(property.propertyClsName, property.propertyName)];
        }
    }
    NSString *mehodStr = @"";
    if (decoderStr.length > 0)
    {
        mehodStr = [NSString stringWithFormat:@"%@\n%@%@%@",mehodStr,kMethodCodeInitPre,decoderStr,kMethodCodeInitTri];
    }
    
    if (encoderStr.length > 0)
    {
        mehodStr = [NSString stringWithFormat:@"%@\n%@%@%@",mehodStr,kMethodEncodePre,encoderStr,kMethodEncodeTri];
    }
    
    if (copyStr.length > 0)
    {
        mehodStr = [NSString stringWithFormat:@"%@\n%@%@%@",mehodStr,kMethodCopyPre(self.clsName),copyStr,kMethodCopyTri];
    }
    
    if (JSONToModel.length > 0)
    {
        mehodStr = [NSString stringWithFormat:@"%@\n%@%@%@",mehodStr,kMethodJSONToModelPre,JSONToModel,kMethodJSONToModelTri];
    }
    
    if (modelToJSON.length > 0)
    {
        mehodStr = [NSString stringWithFormat:@"%@\n%@%@%@",mehodStr,kMethodModelToJSONPre,modelToJSON,kMethodModelToJSONTri];
    }
    return mehodStr;
}

#pragma mark - set
- (void)setClsName:(NSString *)clsName
{
    if (clsName.length > 0)
    {
        _clsName = clsName;
    }
    else
    {
        _clsName = kDetaultClsName;
    }
}

@end

@implementation BXHModelClass(BXHFileString)

- (NSString *)fileHeaderString
{
    NSString *modelHeaderStr = @"";
    NSString *propertString = @"\n";
    for (BXHModelProperty *property in self -> _propertys)
    {
        propertString = [NSString stringWithFormat:@"%@%@",propertString,property.propertyStr];
        if (property.propertModel)
        {
            property.propertModel.needCodeing = self.needCodeing;
            property.propertModel.needCopying = self.needCopying;
            modelHeaderStr = [NSString stringWithFormat:@"%@%@\n",modelHeaderStr,[property.propertModel _fileHeaderStr]];
        }
    }
    return [NSString stringWithFormat:@"%@\n%@%@\n%@%@\n\n\n\n",[self _headerTopStr],modelHeaderStr,self.headerStr,propertString,kFileEnd];
}

- (NSString *)fileImplementationString
{
    NSString *modelImplementationStr = @"";
    for (BXHModelProperty *property in self -> _propertys)
    {
        if (property.propertModel)
        {
            property.propertModel.needCodeing = self.needCodeing;
            property.propertModel.needCopying = self.needCopying;
            modelImplementationStr = [NSString stringWithFormat:@"%@%@\n",modelImplementationStr,[property.propertModel _fileImplementationString]];
        }
    }
    return [NSString stringWithFormat:@"%@\n%@%@\n%@\n%@\n\n\n",[self _implementationTopStr],modelImplementationStr,self.implementationStr,self.methodStr,kFileEnd];
}

- (NSString *)_fileHeaderStr
{
    NSString *modelHeaderStr = @"";
    NSString *propertString = @"\n";
    for (BXHModelProperty *property in self -> _propertys)
    {
        propertString = [NSString stringWithFormat:@"%@%@",propertString,property.propertyStr];
        if (property.propertModel)
        {
            property.propertModel.needCodeing = self.needCodeing;
            property.propertModel.needCopying = self.needCopying;
            modelHeaderStr = [NSString stringWithFormat:@"%@%@\n",modelHeaderStr,[property.propertModel _fileHeaderStr]];
        }
    }
    return [NSString stringWithFormat:@"%@%@\n%@%@\n\n",modelHeaderStr,self.headerStr,propertString,kFileEnd];
}

- (NSString *)_fileImplementationString
{
    NSString *modelImplementationStr = @"";
    for (BXHModelProperty *property in self -> _propertys)
    {
        if (property.propertModel)
        {
            property.propertModel.needCodeing = self.needCodeing;
            property.propertModel.needCopying = self.needCopying;
            modelImplementationStr = [NSString stringWithFormat:@"%@%@\n",modelImplementationStr,[property.propertModel _fileImplementationString]];
        }
    }
    return [NSString stringWithFormat:@"%@%@\n%@\n%@\n\n\n",modelImplementationStr,self.implementationStr,self.methodStr,kFileEnd];
}

- (NSString *)_headerTopStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    [formatter setLocale:[NSLocale currentLocale]];
    
    return kFileHeader(self -> _clsName, [formatter stringFromDate:[NSDate date]]);
}

- (NSString *)_implementationTopStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"yyyy/MM/dd"];
    [formatter setLocale:[NSLocale currentLocale]];
    
    return kFileImplementation(self -> _clsName, [formatter stringFromDate:[NSDate date]]);

}

@end
