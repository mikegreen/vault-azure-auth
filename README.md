# vault-azure-auth-ua-identity

## Scope

1. Create Azure resource group
1. Create user-assigned identity "vault-azure-auth-demo-identity"
1. Create virtual network, subnet, 1 NICs with external IPs
1. Create a Linux VM in only the resource group: example-machine-in-rg
1. Create a Linux VM in the resource group *and* assign it the user-assigned identity created above: example-machine-in-ua

### Auth

#### Resource group auth example

```
$ vault write auth/azure-ua-demo/login role="test-role-rg" \
      jwt="$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-05-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true | jq -r '.access_token')" \
      subscription_id=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-05-01" | jq -r '.compute | .subscriptionId') \
      resource_group_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute | .resourceGroupName')  \
      vm_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute | .name')
```


```
Key                               Value
---                               -----
token                             s.Nsqui31234RPS0123457FsoQ
token_accessor                    12345m1vNOATdCmpR00LjwFM
token_duration                    10m
token_renewable                   true
token_policies                    ["default" "resource-group-policy"]
identity_policies                 []
policies                          ["default" "resource-group-policy"]
token_meta_resource_group_name    example-resource-group
token_meta_role                   test-role-rg
token_meta_subscription_id        02d0e06b-ed9d-4ca5-bb9f-0a0243a9c9f2
token_meta_vm_name                example-machine-in-rg
```

#### User assigned identity auth example

In the JWT call, the client_id is the value from the `vault-azure-auth-demo-identity` Managed Identity.

```
$ vault write auth/azure-ua-demo/login role="test-role-ua"   \
   jwt="$(curl -s 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2021-05-01&resource=https%3A%2F%2Fmanagement.azure.com%2F&client_id=a1155420-e142-4acd-a7a2-9239eae6f061' -H Metadata:true | jq -r '.access_token')"  \ 
   subscription_id=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-05-01" | jq -r '.compute | .subscriptionId')  \     
   resource_group_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute | .resourceGroupName')      \
   vm_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute | .name')
```

```
Key                               Value
---                               -----
token                             s.cOyun123123RQnlhsqe1K9r
token_accessor                    71234PAl6pfQ0dzTL1QwfTU
token_duration                    10m
token_renewable                   true
token_policies                    ["default" "user-assigned-policy"]
identity_policies                 []
policies                          ["default" "user-assigned-policy"]
token_meta_role                   test-role-ua
token_meta_subscription_id        02d0e06b-ed9d-4ca5-bb9f-0a0243a9c9f2
token_meta_vm_name                example-machine-in-ua
token_meta_resource_group_name    example-resource-group
```

### Troubleshooting

`token object id does not match virtual machine identities`
This error indicates the `ua` VM has both a system assigned managed identity and a user assigned identity. 
Remove the system assigned managed identity. 

