#!/bin/bash

PREFIX=$1

PUBLIC_KEY=pub
PRIVATE_KEY=pri

wg genkey | tee $PREFIX-$PRIVATE_KEY | wg pubkey > $PREFIX-$PUBLIC_KEY