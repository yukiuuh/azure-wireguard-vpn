variable "resource_group_name_prefix" {
  default = "rg"
}

variable "resource_group_location" {
  default = "Japan East"
}

variable "wg_clients" {
  type = list(object({
    friendly_name = string,
    public_key    = string,
    private_key   = string,
    client_ip     = string
  }))
}
variable "wg_config_prefix" {
  default = "azure-"
}

variable "wg_server_net" {
  default = "10.1.0.1/24"
}

variable "wg_server_port" {
  default = 51820
}

variable "wg_persistent_keepalive" {
  default = 25
}

variable "wg_server_private_key" {
  type = string
}
variable "wg_server_public_key" {
  type = string
}

variable "wg_server_interface" {
  default = "eth0"
}


