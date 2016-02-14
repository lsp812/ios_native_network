//
//  HttpGeneralEngine.m
//  network
//
//  Created by 大麦 on 15/12/8.
//  Copyright (c) 2015年 lsp. All rights reserved.
//

#import "HttpGeneralEngine.h"



#define KIPADRESS @"http://appapi.pj.damai.cn"

@implementation HttpGeneralEngine

+ (HttpGeneralEngine *) sharedInstance
{
    static dispatch_once_t pred;
    static HttpGeneralEngine *dataEngineInstance = nil;
    dispatch_once(&pred, ^{
        dataEngineInstance = [[HttpGeneralEngine alloc] init];
    });
    return dataEngineInstance;
}

+ (NSOperationQueue *) sharedOperationQueue
{
    static dispatch_once_t pred;
    static NSOperationQueue *operationQueueInstance = nil;
    dispatch_once(&pred, ^{
        operationQueueInstance = [[NSOperationQueue alloc] init];
        operationQueueInstance.name = KIPADRESS;
    });
    return operationQueueInstance;
}


#pragma mark --获取body部分
- (NSString *)HTTPBodyWithParameters:(NSDictionary *)parameters
{
    NSMutableArray *parametersArray = [[NSMutableArray alloc]init];
    
    for (NSString *key in [parameters allKeys]) {
        id value = [parameters objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            [parametersArray addObject:[NSString stringWithFormat:@"%@=%@",key,value]];
        }
    }
    return [parametersArray componentsJoinedByString:@"&"];
}
#pragma mark -- 请求头信息定义
- (NSDictionary *)generateHeader
{
    NSString *merchant_id = @"1";
    NSString *token = @"1";
    NSString *merchant_token = @"1";
    NSString *user_id = @"1";
    NSString *data_version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    //
    NSString *userAgent = [NSString stringWithFormat:@"{\"user_id\":\"%@\",\"merchant_id\":\"%@\",\"token\":\"%@\",\"merchant_token\":\"%@\",\"data_version\":\"%@\"}",user_id,merchant_id,token,merchant_token,data_version];//User-Agent

    //    NSLog(@"userAgent = %@",userAgent);
    NSMutableDictionary *header = [NSMutableDictionary dictionaryWithCapacity:2];
    
    [header setValue:userAgent forKey:@"User-Agent"];
    return header;
    
}
#pragma mark -- 错误处理
- (void)connectErrorWithStatus:(NSInteger )status onComplete:(RequestBlock)block
{
    if (block != nil) {
        NSString* msg = [self getHttpError:status];
        block(nil, RequestErrorCodeConnectError, msg, NO, nil);
    }
}
- (NSString *)getHttpError:(NSInteger )status
{
    switch (status) {
        case HTTP_400:
            return NSLocalizedString(@"请求参数错误", nil);
            break;
        case HTTP_401:
            return NSLocalizedString(@"未授权、未登录", nil);
            break;
        case HTTP_404:
            return NSLocalizedString(@"未找到资源", nil);
            break;
        case HTTP_405:
            return NSLocalizedString(@"请求方法错误", nil);
            break;
        case HTTP_500:
            return NSLocalizedString(@"服务器错误", nil);
            break;
        default:
            return NSLocalizedString(@"当前网络不可用，请检查网络！", nil);
            break;
    }
}
- (BOOL)emptyDictionary:(NSDictionary*)dic
{
    if ([dic isKindOfClass:[NSDictionary class]]) {
        if (dic == nil || [[dic allKeys] count] == 0) {
            return YES;
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
}
- (NSInteger)getSatus:(NSDictionary*)dic
{
    if ([dic isKindOfClass:[NSDictionary class]]) {
        if ([self emptyDictionary:dic]) {//dic是空
            return RequestErrorCodeException;
        }
        NSNumber* status = [dic objectForKey:@"status"];
        if (status == nil) {
            status = [dic objectForKey:@"_status"];
        }
        if (status != nil) {
            if ([status isKindOfClass:[NSNumber class]]) {
                return status.integerValue;
            }
            else if ([status isKindOfClass:[NSString class]]) {
                return [(NSString*)status integerValue];
            }
        }
        else {
            // 服务端不返回code，表示成功
            return HTTP_200;
        }
    }
    return RequestErrorCodeNull;
}
- (void)serverData:(NSDictionary*)dic hasMore:(BOOL)hasMore otherData:(id)otherData onComplete:(RequestBlock)block
{
    if (block != nil) {
        block(dic, HTTP_200, nil, hasMore, otherData);
    }
}
- (void)serverError:(NSInteger)code data:(NSDictionary*)dic onComplete:(RequestBlock)block
{
    if (block != nil) {
        block(dic, code, [dic valueForKey:@"msg"], NO, nil);
    }
}
#pragma mark -- 联网get和post统一调用的公共方法
//可以使用的1
- (NSMutableURLRequest*)systemPublicRequestWithApi:(NSString*)apiName
                                             param:(NSDictionary*)param
                                            method:(NSString*)method
                                        onComplete:(RequestBlock)block
{
    __block NSMutableURLRequest *requestBlock = [[NSMutableURLRequest alloc] init];
    
    [[HttpGeneralEngine sharedOperationQueue] addOperationWithBlock:^{
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            
            //想执行的任务
            NSMutableURLRequest  *request = [[NSMutableURLRequest alloc] init];
            //添加异步线程.
            NSAssert(![apiName hasPrefix:@"/"], @"apiname error /");
            NSString* fullUrl = KIPADRESS;
            if (apiName.length > 0) {
                fullUrl = [NSString stringWithFormat:@"%@/%@", fullUrl, apiName];
            }
            //
            NSString *bodyString = [self HTTPBodyWithParameters:param];
            [request setHTTPMethod:method];
            
            if([method isEqualToString:@"GET"])
            {
                NSURL *u = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",fullUrl,bodyString]];
                [request setURL:u];
            }
            else if([method isEqualToString:@"POST"])
            {
                NSURL *u = [NSURL URLWithString:[NSString stringWithFormat:@"%@",fullUrl]];
                [request setURL:u];
                //
                NSData *bodyData = [[bodyString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]dataUsingEncoding:NSUTF8StringEncoding];//把bodyString转换为NSData数据
                [request setHTTPBody:bodyData];
            }
//            NSError *error = nil;
            //头
            NSDictionary *parameters = [self generateHeader];
            for (NSString *key in [parameters allKeys]) {
                id value = [parameters objectForKey:key];
                if ([value isKindOfClass:[NSString class]]) {
                    [request setValue:value forHTTPHeaderField:key];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                NSData *received = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
                if (received == nil && [received length] < 1)
                {
                    //没网络的情况error 是空
                     [self connectErrorWithStatus:kHttpTimeOutErrorCode onComplete:block];
                }
                else
                {
                    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:received options:NSJSONReadingMutableLeaves error:nil];
                    NSLog(@"dic=%@",dic);
                    NSInteger status = [self getSatus:dic];
                    if (status == HTTP_200) {
                        // 完成
                        if([[dic valueForKey:@"code"]intValue]==0)
                        {
                            [self serverData:dic hasMore:YES otherData:nil onComplete:block];
                        }
                        else
                        {
                            [self serverError:status data:dic onComplete:block];
                        }
                    }
                    else {
                        [self connectErrorWithStatus:status onComplete:block];
                    }
                }
            });
            //将request添加到一个operation里
            requestBlock = request;
        });
    }];
    return requestBlock;
}
#pragma mark -- example
+ (NSString *)isNull:(NSString *)param
{
    if ([param isKindOfClass:[NSNull class]] || param == nil)
    {
        param = @"";
    }
    return param;
}
- (NSMutableURLRequest*)transferIsAllowTransfer:(NSString*)voucher_id
                                     onComplete:(RequestBlock)block
{
    NSString* apiName = @"transfer/is_allow_transfer";
    NSMutableDictionary *param = [NSMutableDictionary dictionaryWithCapacity:2];
    [param setObject:[HttpGeneralEngine isNull:voucher_id] forKey:@"voucher_id"];
    
    
    NSString *method = @"GET";
    return [self systemPublicRequestWithApi:apiName param:param method:method onComplete:block];
}

@end
