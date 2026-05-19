#!/bin/bash
echo 'a1439775520' | sudo -S bash -c 'echo "a1439775520 ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/temp-nopasswd && chmod 440 /etc/sudoers.d/temp-nopasswd'
echo "NOPASSWD configured"
