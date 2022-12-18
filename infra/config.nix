{ config, lib, pkgs, ... }:
let
  org = "bunkbed";
  project = "backbone";
in
{
  # TERRAFORM CONFIG
  terraform.backend.gcs = {
    bucket = "${org}-terraform";
    prefix = "${project}/state";
  };
  provider.google = {
    project = "${org}-${project}";
    region = "us-west1";
    zone = "us-west1-b";
    billing_project = "${org}-billing";
  };

  # EXISTING RESOURCES
  data.google_organization.bunkbedtech = {
    domain = "bunkbed.tech";
  };
  data.google_billing_account.tristan_united = {
    display_name = "tristan-united";
  };

  # NEW RESOURCES
  resource.google_project_service.compute = {
    service = "compute.googleapis.com";
  };
  resource.google_compute_network.vpc = {
    name = "vpc";
    auto_create_subnetworks = false;
  };
  resource.google_compute_subnetwork.${project} = {
    name = "${project}-subnet";
    network = config.resource.google_compute_network.vpc.name;
    ip_cidr_range = "10.10.0.0/24";
  };
  resource.google_project_service.kubernetes = {
    service = "container.googleapis.com";
  };
  resource.google_container_cluster.${project} = {
    name = "${project}-cluster";
    enable_autopilot = true;
    network = config.resource.google_compute_network.vpc.name;
    subnetwork = config.resource.google_compute_subnetwork.${project}.name;
  };
}
