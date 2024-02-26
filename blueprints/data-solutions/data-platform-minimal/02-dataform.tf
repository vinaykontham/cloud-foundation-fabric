# Copyright 2024 Google LLC
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

locals {
  processing-sa-df-default-0 = "serviceAccount:service-${module.processing-project.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

module "processing-sa-df-0" {
  source       = "../../../modules/iam-service-account"
  project_id   = module.processing-project.project_id
  prefix       = var.prefix
  name         = "${var.project_config.project_ids.processing}-df-0"
  display_name = "Dataform processing service account"
}

module "secret" {
  count      = var.enable_services.dataform == true && var.dataform.remote_settings.remote_repository_url != null ? 1 : 0
  source     = "../../../modules/secret-manager"
  project_id = module.processing-project.project_id
  secrets = {
    "${var.dataform.remote_settings.secret_name}" = {
  } }
  versions = {
    "${var.dataform.remote_settings.secret_name}" = {
      "${var.dataform.remote_settings.secret_version}" = { enabled = true, data = var.dataform.remote_settings.token }
    }
  }
}

module "processing-dataform-repository" {
  count           = var.enable_services.dataform == true ? 1 : 0
  source          = "../../../modules/dataform-repository"
  project_id      = module.processing-project.project_id
  region          = var.region
  name            = "${var.prefix}-${var.project_config.project_ids.processing}-df-0"
  service_account = module.processing-sa-df-0.email
  remote_repository_settings = (
    var.dataform.remote_settings.remote_repository_url == null
    ? null
    : {
      url            = var.dataform.remote_settings.remote_repository_url
      secret_version = module.secret[0].version_ids["${var.dataform.remote_settings.secret_name}:${var.dataform.remote_settings.secret_version}"]
    }
  )
  depends_on = [module.processing-sa-df-0]
}

resource "time_sleep" "wait_30_seconds" {
  # Dataforms default service account is only created once the first repository is created. As the following steps require the df SA to be existing, we need to ensure its instantiated before continuing.
  depends_on      = [module.processing-dataform-repository]
  create_duration = "30s"
}

module "processing-sa-df-0-addition" {
  source                 = "../../../modules/iam-service-account"
  service_account_create = false
  project_id             = module.processing-project.project_id
  prefix                 = var.prefix
  name                   = "${var.project_config.project_ids.processing}-df-0"
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      local.groups_iam.data-engineers,
      module.processing-sa-cmp-0.iam_email,
      local.processing-sa-df-default-0
    ],
    "roles/iam.serviceAccountUser" = [
      module.processing-sa-cmp-0.iam_email,
      local.processing-sa-df-default-0
    ]
  }
  depends_on = [time_sleep.wait_30_seconds]
}

module "processing-bq-stg-0" {
  count          = var.enable_services.dataform == true ? 1 : 0
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.processing-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_${replace(var.project_config.project_ids.processing, "-", "_")}_${var.dataform.processing_layers.staging}_bq_0"
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
}

module "processing-bq-trf-0" {
  count          = var.enable_services.dataform == true ? 1 : 0
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.processing-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_${replace(var.project_config.project_ids.processing, "-", "_")}_${var.dataform.processing_layers.transforming}_bq_0"
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
}

module "processing-bq-exp-0" {
  count          = var.enable_services.dataform == true ? 1 : 0
  source         = "../../../modules/bigquery-dataset"
  project_id     = module.processing-project.project_id
  id             = "${replace(var.prefix, "-", "_")}_${replace(var.project_config.project_ids.processing, "-", "_")}_${var.dataform.processing_layers.exposing}_bq_0"
  location       = var.location
  encryption_key = var.service_encryption_keys.bq
}
