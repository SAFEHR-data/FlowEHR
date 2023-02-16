locals {
  subnet_address_spaces = cidrsubnets(var.core_address_space, 1, 3, 3, 3)
}
