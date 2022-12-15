# Copyright 2022 Google LLC
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


variable "prefix" {
  type        = string
  description = "Prefix used for resource creation"
  default     = "private-demo"
}

variable "project_id" {
  description = "GCP Project ID"
  default     = null
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "us-central1"
}

variable "network_name" {
  type        = string
  description = "VPC name"
  default     = "vpc-data"
}

variable "db_password" {
  type        = string
  description = "Database default password"
  default     = "supersecret"
}


variable "resource_labels" {
  type        = map(string)
  description = "Resource labels"
  default = {
    app         = var.prefix
    deployed_by = "cloudbuild"
    env         = "sandbox"
    repo        = "cloud-foundation-fabric"
    terraform   = "true"
  }
}
