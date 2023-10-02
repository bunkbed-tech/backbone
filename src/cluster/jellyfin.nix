{ config, lib, pkgs, ... }:
{
  locals.jellyfin.ports.web = 8096;
  resource.kubernetes_namespace.jellyfin = { metadata.name = "jellyfin"; };
  resource.kubernetes_persistent_volume_claim.jellyfin-config = {
    depends_on = [ "kubernetes_namespace.jellyfin" ];
    metadata.name = "config";
    metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.resources.requests.storage = "3Gi";
    wait_until_bound = false;
  };
  resource.kubernetes_persistent_volume_claim.jellyfin-cache = {
    depends_on = [ "kubernetes_namespace.jellyfin" ];
    metadata.name = "cache";
    metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.resources.requests.storage = "3Gi";
    wait_until_bound = false;
  };
  resource.kubernetes_persistent_volume_claim.jellyfin-media = {
    depends_on = [ "kubernetes_namespace.jellyfin" ];
    metadata.name = "media";
    metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.resources.requests.storage = "30Gi";
    wait_until_bound = false;
  };
  resource.kubernetes_deployment.jellyfin = rec {
    depends_on = [
      "kubernetes_persistent_volume_claim.jellyfin-config"
      "kubernetes_persistent_volume_claim.jellyfin-cache"
      "kubernetes_persistent_volume_claim.jellyfin-media"
    ];
    metadata.name = "jellyfin";
    metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
    metadata.labels.app = metadata.name;
    spec.replicas = 1;
    spec.selector.match_labels = metadata.labels;
    spec.template = {
      metadata.labels = metadata.labels;
      spec.container = {
        image = "docker.io/jellyfin/jellyfin";
        name = "jellyfin";
        env = [{ name = "JELLYFIN_PublishedServerURL"; value = "jellyfin.bunkbed.tech"; }];
        volume_mount = [
          { name = "config"; mount_path = "/config"; }
          { name = "cache"; mount_path = "/cache"; }
          { name = "media"; mount_path = "/media"; }
        ];
        port.container_port = config.locals.jellyfin.ports.web;
      };
      spec.volume = [
        { name = "config"; persistent_volume_claim.claim_name = config.resource.kubernetes_persistent_volume_claim.jellyfin-config.metadata.name; }
        { name = "cache"; persistent_volume_claim.claim_name = config.resource.kubernetes_persistent_volume_claim.jellyfin-cache.metadata.name; }
        { name = "media"; persistent_volume_claim.claim_name = config.resource.kubernetes_persistent_volume_claim.jellyfin-media.metadata.name; }
      ];
    };
  };
  resource.kubernetes_service.jellyfin-web = {
    depends_on = [ "kubernetes_deployment.jellyfin" ];
    metadata.name = "web";
    metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
    spec.selector = config.resource.kubernetes_deployment.jellyfin.metadata.labels;
    spec.port = rec {
      target_port = config.resource.kubernetes_deployment.jellyfin.spec.template.spec.container.port.container_port;
      port = target_port;
    };
  };
  resource.kubernetes_manifest.jellyfin-ingress-route = {
    depends_on = [ "helm_release.traefik" "kubernetes_service.jellyfin-web" ];
    manifest = {
      kind = "IngressRoute";
      apiVersion = "traefik.io/v1alpha1";
      metadata.name = "jellyfin";
      metadata.namespace = config.resource.kubernetes_namespace.jellyfin.metadata.name;
      spec.entryPoints = [ "websecure" ];
      spec.routes = [
        {
          match = "Host(`jellyfin.bunkbed.tech`)";
          kind = "Rule";
          services = [
            {
              name = config.resource.kubernetes_service.jellyfin-web.metadata.name;
              port = config.resource.kubernetes_service.jellyfin-web.spec.port.port;
            }
          ];
        }
      ];
      spec.tls.certResolver = "letsencrypt";
    };
  };
}
