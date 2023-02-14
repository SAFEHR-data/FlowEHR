locals {
  subnet_address_spaces = cidrsubnets(var.core_address_space, 1, 2, 2)
}
