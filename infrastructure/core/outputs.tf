output "core_rg_name" {
    value = azurerm_resource_group.core.name
}

output "core_rg_location" {
    value = azurerm_resource_group.core.location
}

output "core_kv_id" {
    value = azurerm_key_vault.core.id
}
