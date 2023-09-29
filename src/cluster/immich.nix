{ config, lib, pkgs, ... }:
{
  resource.kubernetes_namespace.immich = { metadata.name = "immich"; };
  resource.kubernetes_persistent_volume_claim.immich = {
    depends_on = [ "kubernetes_namespace.immich" ];
    metadata.name = "immich";
    metadata.namespace = config.resource.kubernetes_namespace.immich.metadata.name;
    spec.access_modes = [ "ReadWriteOnce" ];
    spec.resources.requests.storage = "10Gi";
    wait_until_bound = false;
  };
  resource.helm_release.immich = {
    depends_on = [ "kubernetes_persistent_volume_claim.immich" ];
    name = "immich";
    namespace = config.resource.kubernetes_namespace.immich.metadata.name;
    repository = "https://immich-app.github.io/immich-charts";
    chart = "immich";
    version = "0.1.2";
    values = pkgs.lib.backbone.toYAML {
      immich.persistence.library.existingClaim = config.resource.kubernetes_persistent_volume_claim.immich.metadata.name;
      postgresql.enabled = true;
      redis.enabled = true;
    };
  };
  resource.kubernetes_manifest.immich-proxy = {
    depends_on = [ "helm_release.traefik" ];
    manifest = {
      kind = "IngressRoute";
      apiVersion = "traefik.io/v1alpha1";
      metadata.name = "immich-proxy";
      metadata.namespace = config.resource.helm_release.immich.namespace;
      spec.entryPoints = [ "websecure" ];
      spec.routes = [
        {
          match = "Host(`immich.bunkbed.tech`)";
          kind = "Rule";
          services = [ { name = "${config.resource.helm_release.immich.name}-proxy"; port = 8080; } ];
        }
      ];
      spec.tls.certResolver = "letsencrypt";
    };
  };
}
