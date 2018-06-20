//
//  main.m
//  BlockHooker
//
//  Created by 朱来飞 on 2018/6/19.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ASBlockHooker.hpp"
#include <objc/runtime.h>
#include <objc/message.h>
using namespace std ;

//https://opensource.apple.com/source/libclosure/libclosure-67
typedef NS_OPTIONS(int, BlockFlage) {
    BlockFlage_HAS_COPY_DISPOSE =  (1 << 25),
    BlockFlage_HAS_SIGNATURE  =    (1 << 30)
};

struct block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};
struct block_descriptor_2 {
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};
struct block_descriptor_3 {
    const char *signature;
    const char *layout;
};
struct block_layout {
    void *isa;
    volatile int32_t flags;
    int32_t reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor_1 *descriptor;
};
id temp_block_for_block(block_layout * block){
    return nil;
}
const char * signature_for_block(block_layout * block){
    if (! (block->flags & BlockFlage_HAS_SIGNATURE)) return NULL;
    uint8_t *desc = (uint8_t *)block->descriptor;
    desc += sizeof(struct block_descriptor_1);
    if (block->flags & BlockFlage_HAS_COPY_DISPOSE) {
        desc += sizeof(struct block_descriptor_2);
    }
    struct block_descriptor_3 * des3 =  (struct block_descriptor_3 *)desc ;
    return des3->signature;
}
NSMethodSignature * hooker_methodSignatureForSelector(id self,SEL _cmd ,SEL sel){
    block_layout *block =  (__bridge  block_layout *)self;
    const char * signature = signature_for_block(block) ;
    return [NSMethodSignature signatureWithObjCTypes:signature];
}
void hooker_forwardInvocation(id self ,SEL _cmd ,SEL sel){
    block_layout *block =  (__bridge  block_layout *)self;
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

