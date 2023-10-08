//
//  FullyNoded.h
//  FullyNoded
//
//  Created by Peter Denton on 9/14/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

#ifndef Plasma_h
#define Plasma_h

#include "lnsocket.h"
#include "commando.h"
#include "bech32.h"
#include "secp256k1.h"
#include "secp256k1_schnorrsig.h"

void fd_do_zero(fd_set *);
void fd_do_set(int, fd_set *);


#endif /* FullyNoded_h */
