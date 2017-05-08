/* Copyright (c) 2016 Trail of Bits, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

//
//  ViewController.m
//  sep-example
//

#import "ViewController.h"
#import "KeyInterface/KeyInterface.h"

@interface ViewController ()

@end

@implementation ViewController

- (void) viewDidLoad {
    
  [super viewDidLoad];
}

- (void) viewDidAppear:(BOOL)animated {
    
  [super viewDidAppear:animated];
    
  [KeyInterface generateTouchIDKeyPair];
  NSLog(@"Public key raw bits:\n%@", [KeyInterface publicKeyBits]);
  NSString * dataString = @"Hello World";
  
  [KeyInterface generateSignatureForData:[dataString dataUsingEncoding:NSUTF8StringEncoding] withCompletion:^(NSData * success, NSError * error) {
    if (success != nil) {
      NSLog(@"Signature for data: %@", success);
    }
    else {
      NSLog(@"Error: %@", error);
    }
  }];
  
  [KeyInterface deletePrivateKey];
  [KeyInterface deletePublicKey];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
