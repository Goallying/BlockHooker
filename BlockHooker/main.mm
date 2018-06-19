//
//  main.m
//  BlockHooker
//
//  Created by 朱来飞 on 2018/6/19.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ASBlockHooker.hpp"
#import <objc/runtime.h>

//https://opensource.apple.com/source/libclosure/libclosure-67
typedef NS_OPTIONS(int, BlockFlage) {
    BlockFlage_HAS_COPY_DISPOSE =  (1 << 25),
    BlockFlage_HAS_SIGNATURE  =    (1 << 30)
};


const char * signature_for_block(__main_block_impl_0 block){
    
    if (! (block.impl.Flags & BlockFlage_HAS_SIGNATURE)) return NULL;
    uint8_t *desc = (uint8_t *)block.Desc;
    desc += sizeof(struct __main_block_desc_0);
//    if (block.impl.Flags & BlockFlage_HAS_COPY_DISPOSE) {
//        desc += sizeof(struct IIFishBlock_descriptor_2);
//    }
    return nil;
}
NSMethodSignature * hooker_methodSignatureForSelector(id self,SEL _cmd ,SEL sel){
    
    
    return nil;
}
void hooker_forwardInvocation(id self ,SEL _cmd ,SEL sel){
    
    
}
void method_exchange(SEL s1 ,IMP s2){
    
    Class cls = NSClassFromString(@"NSBlock");
    Method mtd = class_getInstanceMethod([NSObject class], s1);
    bool success = class_addMethod(cls, s1, s2, method_getTypeEncoding(mtd));
    if (!success) {
        class_replaceMethod(cls, s1, s2, method_getTypeEncoding(mtd));
    }
}
void swizzle_once(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL orin1 = @selector(methodSignatureForSelector:);
        SEL orin2 = @selector(forwardInvocation:);
        method_exchange(orin1, (IMP)hooker_methodSignatureForSelector);
        method_exchange(orin2, (IMP)hooker_forwardInvocation);
    });
}
void hooker_func_for_block_2(id block){
    swizzle_once();
    struct __main_block_impl_0 * ablk = (__bridge struct __main_block_impl_0 *)block;
    
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        void(^ablock)(void) = ^(){
            NSLog(@"logging in a block");
        };
        //m1
//        struct __main_block_impl_0 * ablk = (__bridge struct __main_block_impl_0 *)ablock;
//        hooker_func_for_block(ablk);
        
        //m2
        hooker_func_for_block_2(ablock);
        ablock();
    }
    return 0;
}

