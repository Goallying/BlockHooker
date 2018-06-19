//
//  ASBlockHooker.cpp
//  BlockerHooker
//
//  Created by 朱来飞 on 2018/6/16.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#include "ASBlockHooker.hpp"
 void fake_func_ptr(){
    printf("---block has been hooked---\n");
}
void hooker_func_for_block(struct __main_block_impl_0 * ablock){
    ablock->impl.FuncPtr = (void*)fake_func_ptr;
}
