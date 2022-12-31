{ domain, ip }:
let service = "mattermost-operator";
in
{
  resource.helm_release.${service} = rec {
    name = service;
    repository = "https://helm.mattermost.com";
    chart = service;
    version = "0.3.3";
    timeout = 600;
    namespace = service;
    set = [ ];
  };
  resource.kubernetes_manifest.mattermost.manifest = rec {
    apiVersion = "installation.mattermost.com/v1beta1";
    kind = "Mattermost";
    metadata = { name = "mattermost"; };
    spec = {
      size = "5users";
      ingress = {
        enabled = true;
        host = "mattermost.${domain}";
        annotations = {
          "kubernetes.io/ingress.class" = "nginx";
        };
      };
      version = "6.0.1";
    };
  };
}
