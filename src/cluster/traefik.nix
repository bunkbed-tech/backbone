{ config, lib, pkgs, ... }:
let
  name = "traefik";
  namespace = name;
  labels.app = name;
  services.web.port = 80;
  mkPort = name: type: { name = name; ${type} = services.${name}.port; };
in {
  resource.helm_release.traefik = {
    name = "traefik";
    namespace = "traefik";
    repository = "https://traefik.github.io/charts";
    chart = "traefik";
    version = "23.1.0";
    create_namespace = true;
    values = pkgs.lib.backbone.toYAML {
      additionalArguments = [
        "--api.insecure"
        "--accesslog"
        "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      ];
      certResolvers.letsencrypt = {
        email = "webmaster@bunkbed.tech";
        tlsChallenge = true;
        storage = "acme.json";
        caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
      ingressRoute.dashboard.entryPoints = [ "websecure" ];
      ingressRoute.dashboard.matchRule = "Host(`traefik.bunkbed.tech`)";
      ingressRoute.dashboard.tls.certResolver = "letsencrypt";
    };
  };
  resource.kubernetes_manifest.whoami = {
    depends_on = [ "helm_release.traefik" ];
    manifest = {
      kind = "IngressRoute";
      apiVersion = "traefik.io/v1alpha1";
      metadata.name = "whoami-tls";
      metadata.namespace = "default";
      spec.entryPoints = [ "websecure" ];
      spec.routes = [
        {
          match = "Host(`whoami.bunkbed.tech`)";
          kind = "Rule";
          services = [ { name = "whoami"; port = services.web.port; } ];
        }
      ];
      spec.tls.certResolver = "letsencrypt";
    };
  };
  resource.kubernetes_deployment.whoami = {
    metadata.name = "whoami";
    metadata.labels.app = "whoami";
    spec.replicas = 1;
    spec.selector.match_labels.app = "whoami";
    spec.template.metadata.labels.app = "whoami";
    spec.template.spec.container = [
      { name = "whoami"; image = "traefik/whoami"; port = [ (mkPort "web" "container_port") ]; }
    ];
  };
  resource.kubernetes_service.whoami = {
    metadata.name = "whoami";
    spec.selector.app = "whoami";
    spec.port = [ (mkPort "web" "port") ];
  };
}