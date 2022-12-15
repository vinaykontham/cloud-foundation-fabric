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

module "vpc" {
  source     = "../../../modules/net-vpc"
  project_id = var.project_id
  name       = "${var.prefix}-vpc"
  subnets = [
    {
      ip_cidr_range = "10.0.0.0/24"
      name          = "gce-${var.region}"
      region        = var.region
    }
  ]
  psa_config = {
    ranges = { servicenetworking = "10.200.0.0/16" }
  }
}

module "nat" {
  source         = "../../../modules/net-cloudnat"
  project_id     = var.project_id
  region         = var.region
  name           = "${var.prefix}-nat"
  router_network = module.vpc.name
}


## Firewall ## 
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-from-iap"
  network = module.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["allow-ssh"]
}
