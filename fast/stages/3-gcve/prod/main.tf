module "project" {
  source          = "../../../../modules/project"
  billing_account = var.billing_account.id
  name            = "prod-gcve-1"
  prefix          = var.prefix
  parent          = var.folder_ids["gcve-prod"]
  group_iam       = var.group_iam
  labels          = var.labels
  iam             = var.iam
  services        = concat(["vmwareengine.googleapis.com"], var.project_services)
}

module "private-cloud" {
  source                    = "../../../../modules/gcve-private-cloud"
  name                      = "prod-gcve-pc-0"
  project_id                = module.project.project_id
  zone                      = var.gcve_private_cloud.zone
  cidr                      = var.gcve_private_cloud.cidr
  vmw_network_create        = true
  management_cluster_config = var.gcve_private_cloud.management_cluster_config
  private_connections = {
    "transit-primary" = {
      name              = "prod-gcve-primary-conn"
      network_self_link = var.vpc_psa_connections.transit-primary.network
      peering_name      = var.vpc_psa_connections.transit-primary.peering
    },
    "shared" = {
      name              = "prod-gcve-shared-conn"
      network_self_link = var.vpc_psa_connections.shared.network
      peering_name      = var.vpc_psa_connections.shared.peering
    }
  }
}
