# kbd_open
#Variables 
VNET_RG="spoke-rg"
SPOKE_VNET_NAME="spoke-vnet-01"

#Gather the spoke vent peering id
PEERING_SPOKE_ID=$(az network vnet show -g 'spoke-rg' --name 'spoke-vnet-01' --query "[virtualNetworkPeerings[].id]" -o tsv)

#Gather remote vent id which were peered with spoke vnet
REMOTE_VNET_IDS=$(az network vnet show -g $VNET_RG --name $SPOKE_VNET_NAME --query "[virtualNetworkPeerings[].remoteVirtualNetwork.id]" -o tsv)

#Gather vnet peering id which peered with spoke vent at remote vnet 
HUB_PEERING_IDS=$(az resource show --ids $REMOTE_VNET_IDS --query "[].properties.virtualNetworkPeerings[].{rg:properties.remoteVirtualNetwork.resourceGroup,peering_id:id}|[?rg=='${VNET_RG}']|[].peering_id" -o tsv)
PEERING_IDS_TO_SYNC=$(echo ${PEERING_SPOKE_ID} ${HUB_PEERING_IDS})
echo $PEERING_IDS_TO_SYNC

#AZ cli command to resync all vnets peering
az network vnet peering sync --ids $PEERING_IDS_TO_SYNC
