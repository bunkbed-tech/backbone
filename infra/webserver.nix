{}:
let
  service = "webserver";
  port = 8080;
in
rec {
  resource.kubernetes_deployment.${service} = rec {
    metadata = rec {
      name = service;
      labels = { app = name; };
      namespace = "default";
    };
    spec = {
      replicas = 1;
      selector.match_labels = metadata.labels;
      template = {
        metadata.labels = metadata.labels;
        spec.container = [
          {
            name = "hello-app";
            image = "gcr.io/google-samples/hello-app:1.0";
            port = [{ container_port = port; }];
          }
        ];
      };
    };
  };
  resource.kubernetes_service.${service} = rec {
    inherit (resource.kubernetes_deployment.${service}) metadata;
    spec = {
      type = "ClusterIP";
      port = [{ inherit port; }];
      selector = metadata.labels;
    };
  };
}
