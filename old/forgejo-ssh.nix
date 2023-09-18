{ config, lib, pkgs, ... }:
{
  resource.kubernetes_manifest.forgejo-ssh = {
    depends_on = [ "helm_release.traefik" ];
    manifest = {
      kind = "IngressRoute";
      apiVersion = "traefik.io/v1alpha1";
      metadata.name = "forgejo-ssh";
      metadata.namespace = "forgejo";
      spec.entryPoints = [ "ssh" ];
      spec.routes = [
        {
          match = "HostSNI(`*`)";
          kind = "Rule";
          services = [ { name = "forgejo-ssh"; port = 22; } ];
        }
      ];
    };
  };
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
        "--entrypoints.ssh.address=:2222/tcp"
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
      ports.ssh.port = 2222;
      ports.ssh.expose = true;
      ports.ssh.exposedPort = 22;
      ports.ssh.protocol = "TCP";
    };
  };

}
