{ project, subnetwork }:
rec {
  resource.google_project_service.compute = {
    service = "compute.googleapis.com";
  };
  resource.google_compute_network.vpc = {
    name = "vpc";
    auto_create_subnetworks = false;
  };
  resource.google_compute_subnetwork.${project} = subnetwork // {
    name = "${project}-subnet";
    network = resource.google_compute_network.vpc.name;
    ip_cidr_range = "10.10.0.0/24";
    private_ip_google_access = true;
  };
  resource.google_compute_firewall.vpc = {
    name = "vpc-firewall";
    network = resource.google_compute_network.vpc.name;
    source_ranges = [ "0.0.0.0/0" ];
    allow = [{ protocol = "tcp"; ports = [ 80 443 ]; }];
  };
}
