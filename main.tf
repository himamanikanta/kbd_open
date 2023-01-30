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