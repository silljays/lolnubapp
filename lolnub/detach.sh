#!/bin/sh

#  detach.sh
#  lolnub
#
#  Created by Anonymous on 11/13/13.
#  Copyright (c) 2015 lolnub.com developers All rights reserved.

hdiutil info | grep .nub | grep \/dev | awk '{ print $3 }' | xargs hdiutil unmount -force