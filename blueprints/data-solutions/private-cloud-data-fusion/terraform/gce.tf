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

data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP"
}

module "vm_cloudsql_proxy" {
  source                 = "../../../../modules/compute-vm"
  project_id             = var.project_id
  zone                   = data.google_compute_zones.available.names[0]
  name                   = "cloudsql-proxy-${local.sql_instance_name}"
  instance_type          = "e2-micro"
  labels                 = var.resource_labels
  tags                   = ["allow-ssh"]
  service_account        = module.sql_client_service_account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  boot_disk = {
    image = "cos-cloud/cos-101-lts"
  }
  network_interfaces = [{
    network    = module.vpc.name
    subnetwork = module.vpc.subnet_self_links["${var.region}/gce"]
  }]
  metadata = {
    startup-script = <<EOF
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install
    docker run -d -p 0.0.0.0:3306:3306 gcr.io/cloudsql-docker/gce-proxy:latest /cloud_sql_proxy -instances=${google_sql_database_instance.instance.connection_name}=tcp:0.0.0.0:3306
    EOF
  }
}

module "vm_mysql_client" {
  source                 = "../../../../modules/compute-vm"
  project_id             = var.project_id
  zone                   = data.google_compute_zones.available.names[0]
  name                   = "mysql-client"
  instance_type          = "e2-micro"
  labels                 = var.resource_labels
  tags                   = ["allow-ssh"]
  service_account        = module.sql_client_service_account.email
  service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  boot_disk = {
    image = "ubuntu-os-cloud/ubuntu-1804-lts"
  }
  network_interfaces = [{
    network    = module.vpc.name
    subnetwork = module.vpc.subnet_self_links["${var.region}/gce"]
  }]
  metadata = {
    startup-script = <<EOF
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    sudo bash add-google-cloud-ops-agent-repo.sh --also-install

    sudo apt update
    sudo apt upgrade -y
    sudo apt install mysql-client -y

    git clone https://github.com/datacharmer/test_db.git
    cd test_db

    MYSQL_IP=${google_sql_database_instance.instance.ip_address.0.ip_address}
    mysql -h$MYSQL_IP -udatafusion -p${var.db_password} < employees.sql
    EOF
  }
}
