#!/usr/bin/env bash

# The following adds the ulserver and ulclient2 IP addresses to the host file, for use in basic network operations
# *
# * (c) Copyright IBM Corporation. 2019
# * SPDX-License-Identifier: Apache-2.0
# * By Kip Twitchell

sed -i '$ a 192.168.10.200 ulserver' /etc/hosts
sed -i '$ a 192.168.10.202 ulclient2' /etc/hosts
