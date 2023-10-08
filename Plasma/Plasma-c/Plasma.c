//
//  FullyNoded.c
//  FullyNoded
//
//  Created by Peter Denton on 9/14/23.
//  Copyright © 2023 Fontaine. All rights reserved.
//

#include "Plasma.h"
#include <sys/select.h>


void fd_do_set(int socket, fd_set *set) {
    FD_SET(socket, set);
}

void fd_do_zero(fd_set *set) {
    FD_ZERO(set);
}
