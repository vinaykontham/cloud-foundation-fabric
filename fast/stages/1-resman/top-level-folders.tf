/**
 * Copyright 2024 Google LLC
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

locals {
  _top_level_path = try(
    pathexpand(var.factories_config.top_level_folders), null
  )
  _top_level_files = try(
    fileset(local._top_level_path, "**/*.yaml"),
    []
  )
  _top_level_folders = {
    for f in local._top_level_files :
    split(".", f)[0] => yamldecode(file(
      "${coalesce(local._top_level_path, "-")}/${f}"
    ))
  }
  top_level_automation = {
    for k, v in local.top_level_folders :
    k => v.automation if(
      try(v.automation.enable, null) == true
      ||
      try(v.automation.cicd_repository, null) != null
    )
  }
  top_level_cicd_repositories = {
    for k, v in local.top_level_folders :
    k => try(v.automation.cicd_repository, null)
    if(
      try(v.automation.cicd_repository, null) != null
      &&
      contains(
        keys(local.identity_providers),
        coalesce(try(v.automation.cicd_repository.identity_provider, null), ":")
      )
      &&
      fileexists(
        "${path.module}/templates/workflow-${try(v.automation.cicd_repository.type, "")}.yaml"
      )
    )
  }
  top_level_folders = merge(
    {
      for k, v in local._top_level_folders : k => merge(v, {
        name = try(v.name, k)
        automation = try(v.automation, {
          enable                      = true
          sa_impersonation_principals = []
        })
        contacts            = try(v.contacts, {})
        firewall_policy     = try(v.firewall_policy, null)
        logging_data_access = try(v.logging_data_access, {})
        logging_exclusions  = try(v.logging_exclusions, {})
        logging_settings    = try(v.logging_settings, null)
        logging_sinks       = try(v.logging_sinks, {})
        # TODO: interpolate automation service accounts
        iam                   = try(v.iam, {})
        iam_bindings          = try(v.iam_bindings, {})
        iam_bindings_additive = try(v.iam_bindings_additive, {})
        iam_by_principals     = try(v.iam_by_principals, {})
        org_policies          = try(v.org_policies, {})
        tag_bindings          = try(v.tag_bindings, {})
      })
    },
    var.top_level_folders
  )
}

module "top-level-folder" {
  source                = "../../../modules/folder"
  for_each              = local.top_level_folders
  parent                = "organizations/${var.organization.id}"
  name                  = each.value.name
  contacts              = each.value.contacts
  firewall_policy       = each.value.firewall_policy
  logging_data_access   = each.value.logging_data_access
  logging_exclusions    = each.value.logging_exclusions
  logging_settings      = each.value.logging_settings
  logging_sinks         = each.value.logging_sinks
  iam                   = each.value.iam
  iam_bindings          = each.value.iam_bindings
  iam_bindings_additive = each.value.iam_bindings_additive
  iam_by_principals     = each.value.iam_by_principals
  org_policies          = each.value.org_policies
  tag_bindings          = each.value.tag_bindings
}

module "top-level-sa" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.top_level_automation
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-0"
  display_name = "Terraform resman ${each.key} folder service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = concat(
      each.value.sa_impersonation_principals,
      compact([
        try(module.top-level-sa-cicd[each.key].iam_email, null)
      ])
    )
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectAdmin"]
  }
}

module "top-level-bucket" {
  source        = "../../../modules/gcs"
  for_each      = local.top_level_automation
  project_id    = var.automation.project_id
  name          = "prod-resman-${each.key}-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin"  = [module.top-level-sa[each.key].iam_email]
    "roles/storage.objectViewer" = [module.top-level-sa[each.key].iam_email]
  }
}

# CI/CD

module "top-level-sa-cicd" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.top_level_cicd_repositories
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-1"
  display_name = "Terraform CI/CD ${each.key} folder service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      each.value.branch == null
      ? format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
      : format(
        local.identity_providers[each.value.identity_provider].principal_branch,
        var.automation.federated_identity_pool,
        each.value.name,
        each.value.branch
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}

module "top-level-r-sa-cicd" {
  source       = "../../../modules/iam-service-account"
  for_each     = local.top_level_cicd_repositories
  project_id   = var.automation.project_id
  name         = "prod-resman-${each.key}-1r"
  display_name = "Terraform CI/CD ${each.key} folder service account (read-only)."
  prefix       = var.prefix
  iam = {
    "roles/iam.workloadIdentityUser" = [
      format(
        local.identity_providers[each.value.identity_provider].principal_repo,
        var.automation.federated_identity_pool,
        each.value.name
      )
    ]
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/logging.logWriter"]
  }
  iam_storage_roles = {
    (var.automation.outputs_bucket) = ["roles/storage.objectViewer"]
  }
}
