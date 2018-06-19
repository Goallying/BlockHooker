//
//  main.m
//  BlockHooker
//
//  Created by 朱来飞 on 2018/6/19.
//  Copyright © 2018年 朱来飞. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "ASBlockHooker.hpp"
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        void(^ablock)(void) = ^(){
            NSLog(@"logging in a block");
        };
        struct __main_block_impl_0 * ablk = (__bridge struct __main_block_impl_0 *)ablock;
        hooker_func_for_block(ablk);
        ablock();
    }
    return 0;
}

