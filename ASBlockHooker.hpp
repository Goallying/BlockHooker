//
//  ASBlockHooker.hpp
//  BlockerHooker
//
//  Created by 朱来飞 on 2018/6/16.
//  Copyright © 2018年 朱来飞. All rights reserved.
//


#ifndef ASBlockHooker_hpp
#define ASBlockHooker_hpp

//#ifdef __OBJC__
//
//
//#endif

#include <stdio.h>
//#include <objc/runtime.h>
//#include <Foundation/Foundation.h>

struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
};
struct __main_block_desc_0 {
    size_t reserved;
    size_t Block_size;
} ;
struct __main_block_impl_0 {
    struct __block_impl impl;
    struct __main_block_desc_0* Desc;
};

void fake_func_ptr(void);
void hooker_func_for_block(struct __main_block_impl_0 * ablock);
//void hooker_func_for_block_2(id block) ;

#endif /* ASBlockHooker_hpp */
