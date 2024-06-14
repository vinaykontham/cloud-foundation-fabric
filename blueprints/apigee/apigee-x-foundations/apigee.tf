/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

module "apigee" {
  source     = "../../../modules/apigee"
  project_id = module.project.project_id
  organization = merge(var.apigee_config.organization, var.network_config.apigee_vpc != null && !var.apigee_config.organization.disable_vpc_peering ? {
    authorized_network = module.apigee_vpc[0].id
    } : var.network_config.shared_vpc != null && !var.apigee_config.organization.disable_vpc_peering ? {
    authorized_network = module.shared_vpc[0].id
    } : {},
    var.apigee_config.organization.database_encryption_key_config.auto_create ? {
      database_encryption_key = module.database_kms[0].keys["database-key"].id
      } : {
      database_encryption_key = var.apigee_config.organization.database_encryption_key_config.id
    },
    var.apigee_config.organization.api_consumer_data_encryption_key_config.auto_create ? {
      api_consumer_data_encryption_key = module.api_consumer_data_kms[0].keys["api-consumer-data-key"].id
      } : {
      api_consumer_data_encryption_key = var.apigee_config.organization.api_consumer_data_encryption_key_config.id
    },
    try(contains(["eu", "us"], var.apigee_config.organization.api_consumer_data_location), false) ?
    var.apigee_config.organization.control_plane_encryption_key_config.auto_create ? {
      control_plane_encryption_key = module.control_plane_kms[0].keys["control-plane-key"].id
      } : {
      control_plane_encryption_key = var.apigee_config.organization.control_plane_encryption_key_config.id
    }
    : {}
    ,
    {
      runtime_type = "CLOUD"
  })
  envgroups    = var.apigee_config.envgroups
  environments = var.apigee_config.environments
  instances = { for k, v in var.apigee_config.instances : k => merge(v, v.disk_encryption_key_config.auto_create ? {
    disk_encryption_key = module.disks_kms[k].key_ids["disk-key"]
  } : {
    disk_encryption_key = v.disk_encryption_key_config.id
  }) }
  endpoint_attachments = var.apigee_config.endpoint_attachments
  addons_config        = var.apigee_config.addons_config
}
