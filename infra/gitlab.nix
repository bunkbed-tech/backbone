{ domain, ip }:
let service = "gitlab";
in
{
  resource.helm_release.${service} = {
    name = service;
    repository = "https://charts.gitlab.io/";
    chart = "gitlab";
    version = "6.6.2";
    timeout = 600;
    namespace = service;
    set = [
      { name = "global.hosts.domain"; value = domain; }
      { name = "global.hosts.externalIP"; value = ip; }
      { name = "global.ingress.annotations.\"kubernetes.io/tls-acme\""; value = true; }
      # Deactivate internal cert-manager because managed externally
      { name = "certmanager.install"; value = false; }
      { name = "global.ingress.configureCertmanager"; value = false; }
      # Deactivate managed global ingress
      { name = "global.ingress.class"; value = "none"; }
      { name = "nginx-ingress.enable"; value = false; }
      # Secrets for individual services
      { name = "gitlab.webservice.ingress.tls.secretName"; value = "gitlab-gitlab-tls"; }
      { name = "registry.ingress.tls.secretName"; value = "gitlab-registry-tls"; }
      { name = "minio.ingress.tls.secretName"; value = "gitlab-minio-tls"; }
      { name = "gitlab.kas.ingress.tls.secretName"; value = "gitlab-kas-tls"; }
    ];
  };
}
