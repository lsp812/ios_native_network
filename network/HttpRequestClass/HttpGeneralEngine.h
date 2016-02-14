//
//  HttpGeneralEngine.h
//  network
//
//  Created by 大麦 on 15/12/8.
//  Copyright (c) 2015年 lsp. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    kHttpTimeOutErrorCode = -1001,//超时
    //
    RequestErrorCodeConnectError = -1,//网络错误
    RequestErrorCodeNull = 32000,//返回的不是字典类型
    RequestErrorCodeException = 32100,//返回的字典是空
    //
    HTTP_200 = 200,//成功
    HTTP_400 = 400,//错误请求，请求参数错误
    HTTP_401 = 401,// 未授权、未登录
    HTTP_404 = 404,// 未找到资源
    HTTP_405 = 405,// 请求方法错误
    HTTP_500 = 500,//服务器内容错误
}RequestStatus;

typedef void(^RequestBlock)(NSDictionary *sourceDic, NSInteger status, NSString *message,BOOL hasMore, id otherData);

@interface HttpGeneralEngine : NSObject

#pragma mark -- 设置网络单例
+ (HttpGeneralEngine *) sharedInstance;

#pragma mark -- 将所有网络请求添加到一个单线程里
+ (NSOperationQueue *) sharedOperationQueue;

#pragma mark-- 公共调用函数
- (NSMutableURLRequest*)systemPublicRequestWithApi:(NSString*)apiName
                                             param:(NSDictionary*)param
                                            method:(NSString*)method
                                        onComplete:(RequestBlock)block;

#pragma mark -- example
- (NSMutableURLRequest*)transferIsAllowTransfer:(NSString*)voucher_id
                                     onComplete:(RequestBlock)block;

@end
