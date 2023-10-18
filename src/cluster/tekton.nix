{ config, lib, pkgs, ... }:
{
  resource.null_resource.tekton-framework =
    let
      pipelines-url = "https://storage.googleapis.com/tekton-releases/pipeline/previous/v0.52.0/release.yaml";
      triggers-url = "https://storage.googleapis.com/tekton-releases/triggers/previous/v0.25.0/release.yaml";
      interceptors-url = "https://storage.googleapis.com/tekton-releases/triggers/previous/v0.25.0/interceptors.yaml";
      dashboard-url = "https://storage.googleapis.com/tekton-releases/dashboard/previous/v0.40.1/release.yaml";
    in {
      provisioner.local-exec.command = ''
        kubectl --context ${config.kubernetes.context} apply -f ${pipelines-url}
        kubectl --context ${config.kubernetes.context} apply -f ${triggers-url}
        kubectl --context ${config.kubernetes.context} apply -f ${interceptors-url}
        kubectl --context ${config.kubernetes.context} apply -f ${dashboard-url}
      '';
    };
  resource.kubernetes_namespace.tekton = { metadata.name = "tekton"; };
  resource.kubernetes_manifest.tekton-dashboard-ingressroute = {
    depends_on = [ "helm_release.traefik" ];
    manifest = {
      kind = "IngressRoute";
      apiVersion = "traefik.io/v1alpha1";
      metadata.name = "tekton-dashboard";
      metadata.namespace = config.resource.kubernetes_namespace.tekton.metadata.name;
      spec.entryPoints = [ "websecure" ];
      spec.routes = [
        {
          match = "Host(`tekton.bunkbed.tech`)";
          kind = "Rule";
          services = [ { name = "tekton-dashboard"; port = 9097; } ];
        }
      ];
      spec.tls.certResolver = "letsencrypt";
    };
  };
}
