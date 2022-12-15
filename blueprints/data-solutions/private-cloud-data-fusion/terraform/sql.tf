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

locals {
  sql_instance_name = "mysql-${random_id.db_name_suffix.hex}"
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "instance" {
  name                = local.sql_instance_name
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false # not recommended for PROD

  settings {
    tier        = "db-custom-1-3840"
    user_labels = var.resource_labels

    ip_configuration {
      private_network = module.vpc.self_link
      ipv4_enabled    = false
    }
  }
}

resource "google_sql_user" "datafusion" {
  instance = google_sql_database_instance.instance.id
  name     = "datafusion"
  password = var.db_password
}
