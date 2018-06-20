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

const void * blockKey = "blockKey";
const void * disposeKey = "disposeKey";

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

static struct block_descriptor_2 * _block_descriptor_2(block_layout * aBlock)
{
    if (! (aBlock->flags & BlockFlage_HAS_COPY_DISPOSE)) return NULL;
    uint8_t *desc = (uint8_t *)aBlock->descriptor;
    desc += sizeof(struct block_descriptor_1);
    return (struct block_descriptor_2 *)desc;
}
static struct block_descriptor_3 * _block_descriptor_3(block_layout* aBlock)
{
    if (! (aBlock->flags & BlockFlage_HAS_SIGNATURE)) return NULL;
    uint8_t *desc = (uint8_t *)aBlock->descriptor;
    desc += sizeof(struct block_descriptor_1);
    if (aBlock->flags & BlockFlage_HAS_COPY_DISPOSE) {
        desc += sizeof(struct block_descriptor_2);
    }
    struct block_descriptor_3 * des3 =  (struct block_descriptor_3 *)desc ;
    return des3;
}
id temp_block_for_block(block_layout * block){
    id blk = (__bridge id)block ;
    return objc_getAssociatedObject(blk, blockKey);
}
void set_temp_block(block_layout * block,block_layout * tp){
    objc_setAssociatedObject((__bridge id)block, "blockKey", (__bridge id)tp, OBJC_ASSOCIATION_ASSIGN);
}
static long long block_get_disposeFunc(id block) {
    return [objc_getAssociatedObject(block, disposeKey) longLongValue];
}
static void block_set_disposeFunc(id block, long long disposeFuncAdders) {
    objc_setAssociatedObject(block, disposeKey, @(disposeFuncAdders), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
void block_disposeFunc(const void * block) {
    block_layout * ablock = (block_layout *)block;
    id tempBlock = temp_block_for_block(ablock);
    free((__bridge void *)tempBlock);
    long long disposeAdders = block_get_disposeFunc((__bridge id)(block));
    void (*disposeFunc)(const void *) = (void (*)(const void *))disposeAdders;
    if (disposeFunc) {
        disposeFunc(block);
    }
}
static void block_dispose_hooker(block_layout * block) {
    if (block->flags & BlockFlage_HAS_COPY_DISPOSE) {
        struct block_descriptor_2 *des2  = _block_descriptor_2(block);
        if (des2->dispose != block_disposeFunc) {
            long long disposeAdders = (long long)des2->dispose;
            block_set_disposeFunc((__bridge id)(block), disposeAdders);
            des2->dispose = block_disposeFunc;
        }
    }
}
void new_block(block_layout * block){
    struct block_descriptor_2 *des2 = _block_descriptor_2(block);
    if (des2) {
        block_layout * newBlock =  (block_layout *)malloc(block->descriptor->size);
        if(!newBlock) return ;
        memmove(newBlock, block, block->descriptor->size);
        des2->copy(newBlock, block);
        set_temp_block(block, newBlock);
        block_dispose_hooker(block);
    }
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
void hooker_forwardInvocation(id self ,SEL _cmd ,NSInvocation *invo){
    
    //core
    block_layout * block =  (__bridge block_layout *)invo.target ;
    id ablock = temp_block_for_block(block);
    invo.target = ablock ;
    [invo invoke];
    NSLog(@"block been hooked");
}
static IMP get_MsgForward(const char *methodTypes) {
    IMP msgForwardIMP = _objc_msgForward;
#if !defined(__arm64__)
    if (methodTypes[0] == '{') {
        NSMethodSignature *methodSignature = [NSMethodSignature signatureWithObjCTypes:methodTypes];
        if ([methodSignature.debugDescription rangeOfString:@"is special struct return? YES"].location != NSNotFound) {
            msgForwardIMP = (IMP)_objc_msgForward_stret;
        }
    }
#endif
    return msgForwardIMP;
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
    struct block_layout * ablk = (__bridge struct block_layout *)block;
    if(!temp_block_for_block(ablk)){
        new_block(ablk);
        struct block_descriptor_3 *des3 =  _block_descriptor_3(ablk);
        ablk->invoke = (void (*)(void *,...))get_MsgForward(des3->signature);
    }
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

