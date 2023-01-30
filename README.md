# kbd_open

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "hw_reg_details" {
  type = map(object({
    automation_acc_name = string
    resource_group_name = string
    hwg_name = string
    hybrid_workers = list(string)
  }))
  default = {
    hw_reg_details1 = {
    automation_acc_name = "auto23"
    resource_group_name = "auto-test"
    hwg_name = "hybridworker11"
    hybrid_workers = ["vm11", "vm12"]
   }
    hw_reg_details2 = {
    automation_acc_name = "auto-24"
    resource_group_name = "auto-test"
    hwg_name = "hybridworker21"
    hybrid_workers = ["vm21", "vm22"]
   }
  } 
}

locals {
  hw_reg_list = flatten ([
    for hw_detail_key, hw_detail_value in var.hw_reg_details : [
      for hw_name in hw_detail_value.hybrid_workers :  {
      #for hwg_name in hwg_lists.hybrid_worker_group :  {
        automation_acc_name = hw_detail_value.automation_acc_name,
        resource_group_name = hw_detail_value.resource_group_name,
        hwg_name            = hw_detail_value.hwg_name,
        hw_name             = hw_name
      } 
    ]
    ])
  hw_reg_map = {
    for hw_details in local.hw_reg_list : "${hw_details.automation_acc_name}-${hw_details.hwg_name}-${hw_details.hw_name}" => hw_details 
  }

  ouput = { for x in azurerm_automation_hybrid_runbook_worker.hwreg : "Automation Account : ${x.automation_account_name}" => {
            for y in azurerm_automation_hybrid_runbook_worker.hwreg : "${x.worker_group_name}" => "vm : ${element(split("/", y.vm_resource_id),8)} -- Registered id : ${y.worker_id}"...if y.worker_group_name == x.worker_group_name}...}
}

data "azurerm_automation_account" "this" {
  for_each            = local.hw_reg_map
  name                = each.value.automation_acc_name
  resource_group_name = each.value.resource_group_name
}

data "azurerm_virtual_machine" "this" {
  for_each            = local.hw_reg_map
  name                = each.value.hw_name
  resource_group_name = each.value.resource_group_name
}

resource "random_uuid" "hw_uuid" {
  for_each = local.hw_reg_map
}

resource "azurerm_automation_hybrid_runbook_worker" "hwreg" {
  for_each = local.hw_reg_map
  resource_group_name     = each.value.resource_group_name
  automation_account_name = each.value.automation_acc_name
  worker_group_name       = each.value.hwg_name
  vm_resource_id          = data.azurerm_virtual_machine.this[each.key].id
  worker_id               = random_uuid.hw_uuid[each.key].result
}

#output "hybrid_worker_registered_details" {
#  #value = { for x in azurerm_automation_hybrid_runbook_worker_group.test : "${x.automation_account_name}" => "${x.name}"... }
#  #value = { for x in azurerm_automation_hybrid_runbook_worker.hwreg : "Automation Account : ${x.automation_account_name}" =>
#  # "${x.worker_group_name} = [vm:: ${element(split("/", x.vm_resource_id),8)} -- Registered id ::${x.worker_id}]"...}
#  #value = merge({ for x in azurerm_automation_hybrid_runbook_worker.hwreg : "Automation Account : ${x.automation_account_name}" => {
#   #         for y in azurerm_automation_hybrid_runbook_worker.hwreg : "${x.worker_group_name}" => "vm : ${element(split("/", y.vm_resource_id),8)} -- Registered id : ${x.worker_id}"if y.vm_resource_id == x.vm_resource_id }...})
#   value = { for k ,v in local.ouput: k => { for i,j in v : i => j...} }
#}

output "test" {
  value = local.ouput
  
}
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#####################################################################################################################################################################

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=2.91.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "hwg_details" {
  type = map(object({
    automation_acc_name = string
    resource_group_name = string
    hwg_names = list(string)
  }))
  default = {
    hwg_details1 = {
    automation_acc_name = "auto23"
    resource_group_name = "auto-test"
    hwg_names = ["hybridworker11", "hybridworker12"]
   }
   hwg_details2 = {
    automation_acc_name = "auto-24"
    resource_group_name = "auto-test"
    hwg_names = ["hybridworker21", "hybridworker22"]
   }
  } 
}

locals {
  hwg_details_list = flatten ([
    for hwg_detail_key, hwg_detail_value in var.hwg_details : [
      for hwg_name in hwg_detail_value.hwg_names :  {
      #for hwg_name in hwg_lists.hybrid_worker_group :  {
        automation_acc_name = hwg_detail_value.automation_acc_name,
        resource_group_name = hwg_detail_value.resource_group_name,
        hwg_name            = hwg_name
      } 
    ]
    ])
  hwg_details_map = {
    for hwg_details in local.hwg_details_list : "${hwg_details.automation_acc_name}-${hwg_details.hwg_name}" => hwg_details 
  }
}

data "azurerm_automation_account" "this" {
  for_each            = local.hwg_details_map
  name                = each.value.automation_acc_name
  resource_group_name = each.value.resource_group_name
}
resource "azurerm_automation_hybrid_runbook_worker_group" "test" {
  for_each                = local.hwg_details_map
  name                    = each.value.hwg_name
  resource_group_name     = each.value.resource_group_name
  automation_account_name = data.azurerm_automation_account.this[each.key].name
}

output "name" {
  value = { for x in azurerm_automation_hybrid_runbook_worker_group.test : "${x.automation_account_name}" => "${x.name}"... }
}
