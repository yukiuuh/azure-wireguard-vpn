#!/bin/bash

PEM=$1
BASTION_PUBLIC_IP=`terraform output -raw bastion_public_ip_address`

ssh -i $PEM azureuser@$BASTION_PUBLIC_IP