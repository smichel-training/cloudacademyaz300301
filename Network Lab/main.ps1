# Set default location to WestUS2 where Lab resources are located
az configure --defaults location=westus2
az network vnet list --output table

# List the subnet in the app virtual network
$resource_group=$(az group list --query [].name --output tsv)
az network vnet subnet list --resource-group $resource_group --vnet-name app --output table

# Query the subnet's network security group (NSG) ID:
# output tsv : Tab-separated values, with no keys (https://docs.microsoft.com/bs-cyrl-ba/cli/azure/format-output-azure-cli?view=azure-cli-latest)
az network vnet subnet list --resource-group $resource_group --vnet-name app --query [].networkSecurityGroup.id --output tsv

# List the rules in the website-vmssnsg NSG:
# output jsonc : Colored json
az network nsg rule list --resource-group $resource_group --nsg-name website-vmssnsg --output jsonc

# Page through the output of the VMSS by pressing spacebar after entering
az vmss list --output jsonc | more

# Create a subnet in the app virtual network
az network vnet subnet create --resource-group $resource_group --vnet-name app --name app-gw --address-prefix 10.0.100.0/24

# Create a public IP address for the Application Gateway frontend
# The dynamic allocation method means that an IP address will be assigned when the public IP is associated with a resource. Static allocation 
# can be used to reserve an address that won't change when it is not associated with a resource, for a cost. Currently the public IP is not associated 
# so the ipAddress is null
az network public-ip create --resource-group $resource_group --name app-gw-ip --allocation-method Dynamic

#Read through the available configuration options for creating an Application Gateway and consider what options are needed to meet the requirements, 
# pressing spacebar to advance the output:
az network application-gateway create -h

# Create an Application Gateway the satisfies the requirements
# Creation may take up to 20 min
az network application-gateway create --resource-group $resource_group --vnet-name app --subnet app-gw `
    --name app-gw --capacity 1 --frontend-port 80 `
    --http-settings-cookie-based-affinity Disabled `
    --http-settings-port 80 --http-settings-protocol Http `
    --public-ip-address app-gw-ip --sku Standard_Small `
    --no-wait

# Run a custom script that deploys a web application on the VMSS instances using an extension
# Not working in Powershell 6 Terminal - Have to use Cloud shell / bash
az vmss extension set --resource-group $resource_group --vmss-name website-vmss `
    --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript `
    --settings '{"fileUris": ["https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/app-gw/deploy.sh"], "commandToExecute": "./deploy.sh"}'

# Same command which should work with Powershell 6 Terminal (not tested)
az vmss extension set --resource-group $resource_group --vmss-name website-vmss `
    --publisher Microsoft.Azure.Extensions --version 2.0 --name CustomScript `
    --settings '{\"fileUris\": [\"https://raw.githubusercontent.com/cloudacademy/azure-lab-provisioners/master/app-gw/deploy.sh\"], \"commandToExecute\": \"./deploy.sh\"}'

# You can wait until the Application Gateway provisioning completes by issuing
az network application-gateway wait --resource-group $resource_group --name app-gw --created

# Inspect the network interface configuration of the VMSS
az vmss show --resource-group $resource_group --name website-vmss `
    --query virtualMachineProfile.networkProfile.networkInterfaceConfigurations

# Review the properties of the Application Gateway focusing on relevant backend address pool values
az network application-gateway show --resource-group $resource_group --name app-gw | more

# Extract the backend pool ID and store it in a variable
$backend_pool_id=$(az network application-gateway show --resource-group $resource_group --name app-gw --query backendAddressPools[0].id)

# Update the VMSS backend pool configuration to reference the Application Gateway's default backend pool by ID:
# Only working in cloud shell
az vmss update --resource-group $resource_group --name website-vmss `
  --add virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools "{'id':$backend_pool_id}"

  # Get the public IP address associated with the Application Gateway frontend
az network public-ip show --resource-group $resource_group --name app-gw-ip --query ipAddress --output tsv
