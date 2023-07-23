{ config, lib, pkgs, ... }:
let
  name = "traefik";
  namespace = name;
  labels.app = name;
  services.web.port = 80;
  mkPort = name: type: { name = name; ${type} = services.${name}.port; };
in {
  resource.helm_release.traefik = {
    inherit name namespace;
    repository = "https://traefik.github.io/charts";
    chart = "traefik";
    version = "23.1.0";
    create_namespace = true;
    values = pkgs.lib.backbone.toYAML {
      additionalArguments = [
        "--api.insecure"
        "--accesslog"
      ];
      certResolvers.letsencrypt = {
        email = "webmaster@bunkbed.tech";
        tlsChallenge = true;
        storage = "acme.json";
        caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
      };
    };
  };
        {
        }
      ];
    };
  };
}
