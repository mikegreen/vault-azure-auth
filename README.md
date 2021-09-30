# vault-azure-auth

## Scope

1. Create Azure resource group
1. Create user-assigned identity "vault-azure-auth-demo-identity"
1. Create virtual network, subnet, 1 NICs with external IPs
1. Create a Linux VM in only the resource group: example-machine-in-rg
1. Create a Linux VM in the resource group *and* assign it the user-assigned identity created above: example-machine-in-ua

