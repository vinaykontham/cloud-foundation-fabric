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


module "datafusion" {
  source = "../../../../modules/datafusion"

  project_id                    = var.project_id
  name                          = var.cdf_instance_name
  description                   = "Cloud Data Fusion private instance"
  region                        = var.region
  network                       = module.vpc.name
  ip_allocation_create          = false
  ip_allocation                 = var.cdf_cidr
  type                          = var.cdf_type
  enable_stackdriver_logging    = true
  enable_stackdriver_monitoring = true
  labels                        = var.resource_labels
}

resource "google_compute_firewall" "allow_private_data_fusion" {
  name        = "${module.vpc.name}-allow-private-cdf"
  description = "Allow Cloud Data Fusion to access the proxy VMs"
  network     = module.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "3306", "5432", "1433"]
  }

  source_ranges = [var.cdf_cidr]
}
