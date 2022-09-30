#!/bin/bash

PEM=$1
BASTION_PUBLIC_IP=`terraform output -raw bastion_public_ip_address`
WG_PRIVATE_IP=`terraform output -raw wg_private_ip_address`
PROXY_COMMAND="ssh -i $PEM -W %h:%p azureuser@$BASTION_PUBLIC_IP"

ssh -o ProxyCommand="$PROXY_COMMAND" -i $PEM azureuser@$WG_PRIVATE_IP