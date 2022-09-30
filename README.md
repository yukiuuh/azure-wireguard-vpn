# azure-wireguard-vpn

Example terraform project to deploy wireguard server and ssh server to Azure

## Requirements

Requirements for client Windows machine
- Git Bash
- Azure CLI
- Terraform
- WireGuard

## Usage

### Install WireGuard to Windows client machine

### Setup Azure and Terraform

https://learn.microsoft.com/ja-jp/azure/developer/terraform/get-started-windows-bash?tabs=bash

### Generate WireGuard keypairs

open Git Bash

``` 
cd ./wgkeys

../generate_wg_key_pair.sh Server

../generate_wg_key_pair.sh Home
../generate_wg_key_pair.sh Office

cd ..
```

### Setup terraform.tfvars

```
cp terraform.tfvars.example terraform.tfvars
```

and edit terraform.tfvars

### Deploy

```
terraform init
terraform plan
terraform apply
```

### Setup WireGuard

.conf files are generated in  ```clients``` directory

put the file on each client

### SSH connection (for debug)

```
terraform output -raw tls_private_key > azure.pem

./connect_bastion.sh ./azure.pem

./connect_wg.sh ./azure.pem
```

### Destroy

```
terraform plan -destroy
terraform apply -destroy
```