{ config, lib, pkgs, ... }:
let
  name = "traefik";
  namespace = name;
  labels.app = name;
  services = { dashboard.port = 8080; web.port = 80; };
in {
  config = lib.mkIf (config.kubernetes.version == "k8s") {
    resource.kubernetes_namespace.traefik = { metadata.name = name; };
    resource.kubernetes_cluster_role.traefik = {
      metadata.name = name;
      rule = [
        {
          api_groups = [ "" ];
          resources = [ "services" "endpoints" "secrets" ];
          verbs = [ "get" "list" "watch" ];
        }
        {
          api_groups = [ "extensions" "networking.k8s.io" ];
          resources = [ "ingresses" "ingressclasses" ];
          verbs = [ "get" "list" "watch" ];
        }
        {
          api_groups = [ "extensions" "networking.k8s.io" ];
          resources = [ "ingresses/status" ];
          verbs = [ "update" ];
        }
      ];
    };
    resource.kubernetes_service_account.traefik = {
      depends_on = [ "kubernetes_namespace.traefik" ];
      metadata = { inherit name namespace; };
    };
    resource.kubernetes_cluster_role_binding.traefik = {
      depends_on = [ "kubernetes_cluster_role.traefik" "kubernetes_service_account.traefik" ];
      metadata.name = name;
      role_ref = { api_group = "rbac.authorization.k8s.io"; kind = "ClusterRole"; name = name; };
      subject = [ { inherit name namespace; kind = "ServiceAccount"; } ];
    };
    resource.kubernetes_deployment.traefik = {
      depends_on = [ "kubernetes_cluster_role_binding.traefik" ];
      metadata = { inherit name namespace labels; };
      spec.replicas = 1;
      spec.selector.match_labels = labels;
      spec.template.metadata.labels = labels;
      spec.template.spec.service_account_name = name;
      spec.template.spec.container = [
        {
          name = name;
          image = "traefik:v2.10";
          args = [ "--api.insecure" "--providers.kubernetesingress" ];
          port = lib.attrsets.mapAttrsToList (_name: service: { name = _name; container_port = service.port; }) services;
        }
      ];
    };
    resource.kubernetes_service = pkgs.lib.backbone.mkResources {} (_name: service: {
      depends_on = [ "kubernetes_deployment.traefik" ];
      metadata.name = "${name}-${_name}";
      metadata.namespace = namespace;
      spec.type = "LoadBalancer";
      spec.port = [ { port = service.port; target_port = _name; } ];
      spec.selector = labels;
    }) services;
  };
}
