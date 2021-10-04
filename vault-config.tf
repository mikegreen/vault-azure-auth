
# SP for UA identity 
# 573ad681-9d09-4b51-86df-338d1c40c99b

resource "vault_auth_backend" "example" {
  type = "azure"
  path = "azure-ua-demo"
  tune {
    max_lease_ttl     = "60m"
    default_lease_ttl = "30m"
  }
}

variable "azure_tenant_id" {
  type        = string
  description = "The tenant id for the Azure Active Directory organization"
}

variable "azure_client_id" {
  type        = string
  description = ""
}

variable "azure_client_secret" {
  type        = string
  description = ""
}

resource "vault_azure_auth_backend_config" "example" {
  backend       = vault_auth_backend.example.path
  tenant_id     = var.azure_tenant_id
  client_id     = var.azure_client_id
  client_secret = var.azure_client_secret
  resource      = "https://management.azure.com/"
}

resource "vault_azure_auth_backend_role" "user-assigned-role" {
  backend                     = vault_auth_backend.example.path
  role                        = "test-role-ua"
  bound_service_principal_ids = [azurerm_user_assigned_identity.example.principal_id] # 573ad681-9d09-4b51-86df-338d1c40c99b
  bound_resource_groups       = [azurerm_resource_group.example.name]
  token_ttl                   = 600
  token_max_ttl               = 600
  token_policies              = ["default", vault_policy.user-assigned.name]
}

resource "vault_azure_auth_backend_role" "resource-group-role" {
  backend               = vault_auth_backend.example.path
  role                  = "test-role-rg"
  bound_resource_groups = [azurerm_resource_group.example.name]
  token_ttl             = 600
  token_max_ttl         = 600
  token_policies        = ["default", vault_policy.resource-group.name]
}

# create KV mounts for each 
resource "vault_mount" "ua-secrets" {
  type = "kv"
  path = "ua-secrets"
}

resource "vault_mount" "rg-secrets" {
  type = "kv"
  path = "rg-secrets"
}

# Create the data for the policy
data "vault_policy_document" "user-assigned" {
  rule {
    path         = "/ua-secrets/*"
    capabilities = ["create", "read", "update", "list"]
    description  = ""
  }
}

data "vault_policy_document" "resource-group" {
  rule {
    path         = "/rg-secrets/*"
    capabilities = ["create", "read", "update", "list"]
    description  = ""
  }
}

# create policies 
resource "vault_policy" "user-assigned" {
  name   = "user-assigned-policy"
  policy = data.vault_policy_document.user-assigned.hcl
}

resource "vault_policy" "resource-group" {
  name   = "resource-group-policy"
  policy = data.vault_policy_document.resource-group.hcl
}
