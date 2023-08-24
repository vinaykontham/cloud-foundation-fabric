# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# generate tfvars file for subsequent stages
locals {
  tfvars = {
    project_id                = module.project.project_id
    hcx                       = module.private-cloud.hcx
    id                        = module.private-cloud.id
    management_cluster        = module.private-cloud.management_cluster
    network_config            = module.private-cloud.network_config
    nsx                       = module.private-cloud.nsx
    private-cloud             = module.private-cloud.private-cloud
    private_connections_setup = module.private-cloud.private_connections_setup
  }

}

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${pathexpand(var.outputs_location)}/tfvars/3-gcve-prod.tfvars.json"
  content         = jsonencode(local.tfvars)
}

resource "google_storage_bucket_object" "tfvars" {
  bucket  = var.automation.outputs_bucket
  name    = "tfvars/3-gcve.tfvars.json"
  content = jsonencode(local.tfvars)
}

# outputs
output "project_id" {
  description = "Details about a HCX Cloud Manager appliance."
  value       = module.project.project_id
}

output "hcx" {
  description = "Details about a HCX Cloud Manager appliance."
  value       = module.private-cloud.hcx
}

output "id" {
  description = "ID of the private cloud."
  value       = module.private-cloud.id
}

output "management_cluster" {
  description = "Details of the management cluster of the private cloud."
  value       = module.private-cloud.management_cluster
}

output "network_config" {
  description = "Details about the network configuration of the private cloud."
  value       = module.private-cloud.network_config
}

output "nsx" {
  description = "Details about a NSX Manager appliance."
  value       = module.private-cloud.nsx
}

output "private-cloud" {
  description = "The private cloud resource."
  value       = module.private-cloud.private-cloud
}

output "private_connections_setup" {
  description = "Cloud SDK commands for the private connections manual setup."
  value       = module.private-cloud.private_connections_setup
}

