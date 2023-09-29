{ config, lib, pkgs, ... }:
{
  config.terraform.required_providers.k3d = { source = "pvotal-tech/k3d"; version = "0.0.7"; };
  config.provider.k3d = {};
  config.resource.k3d_cluster.bunkbed = {
    name = "bunkbed";
    image = "docker.io/rancher/k3s:v1.27.5-k3s1";
    agents = 3;
    port = { host_port = 4443; container_port = 443; node_filters = [ "loadbalancer" ]; };
    k3s = { extra_args = [ { arg = "--disable=traefik"; node_filters = [ "server:0" ]; } ]; };
    kubeconfig.update_default_kubeconfig = true;
  };
  config.resource.helm_release.traefik.depends_on = [ "k3d_cluster.bunkbed" ];
}
