{ config, lib, pkgs, ... }:
let name = "traefik";
in {
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
    metadata.name = name;
    metadata.namespace = config.resource.kubernetes_namespace.traefik.metadata.name;
  };
  resource.kubernetes_cluster_role_binding.traefik = {
    metadata.name = name;
    role_ref = { api_group = "rbac.authorization.k8s.io"; kind = "ClusterRole"; name = name; };
    subject = [
      {
        kind = "ServiceAccount";
        name = name;
        namespace = config.resource.kubernetes_namespace.traefik.metadata.name;
      }
    ];
  };
  resource.kubernetes_deployment.traefik = rec {
    metadata.name = name;
    metadata.namespace = config.resource.kubernetes_namespace.traefik.metadata.name;
    metadata.labels.app = name;
    spec.replicas = 1;
    spec.selector.match_labels = metadata.labels;
    spec.template.metadata.labels = metadata.labels;
    spec.template.spec.service_account_name = config.resource.kubernetes_service_account.traefik.metadata.name;
    spec.template.spec.containers = [
      {
        name = name;
        image = "traefik:v2.10";
        args = [ "--api.insecure" "--providers.kubernetesingress" ];
        ports = [
          { name = "web"; container_port = 80; }
          { name = "dashboard"; container_port = 8080; }
        ];
      }
    ];
  };
  resource.kubernetes_service.traefik-dashboard = {
    metadata.name = "${name}-dashboard";
    metadata.namespace = config.resource.kubernetes_namespace.traefik.metadata.name;
    spec.type = "LoadBalancer";
    spec.ports = [ { port = 8080; target_port = "dashboard"; } ];
    spec.selector = config.resource.kubernetes_deployment.traefik.spec.selector.match_labels;
  };
  resource.kubernetes_service.traefik-web = {
    metadata.name = "${name}-web";
    metadata.namespace = config.resource.kubernetes_namespace.traefik.metadata.name;
    spec.type = "LoadBalancer";
    spec.ports = [ { port = 80; target_port = "web"; } ];
    spec.selector = config.resource.kubernetes_deployment.traefik.spec.selector.match_labels;
  };
}
