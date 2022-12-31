{ domain, webserver, ingress-pool }:
let service = "nginx";
in
rec {
  resource.kubernetes_config_map.${service} = {
    metadata = {
      name = service;
      default.conf = ''
        # Allow variables in proxy_pass + bypass startup checks
        # Variables must use: FQDN <service>.<namespace>.svc.cluster.local
        resolver kube-dns.kube-system.svc.cluster.local valid=30s ipv6=off;

        server {
          listen 80;
          listen [::]:80;
          server_name ${domain};
          return 301 https://$host$request_uri;
        }

        server {
          listen 443 ssl;
          server_name ${domain};
          ssl_certificate /cert/fullchain.pem;
          ssl_certificate_key /cert/privkey.pem;
          ssl_protocols TLSv1.2;
          ssl_ciphers HIGH:!aNULL:!MD5;

          location / {
            set $upstream "http://${webserver.name}.${webserver.namespace}.svc.cluster.local:8080";
            proxy_pass $upstream;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          }

          error_page 500 502 503 504 /50x.html;
          location = /50x.html {
            root /usr/share/nginx/html;
          }
        }
      '';
    };
  };
  resource.kubernetes_deployment.${service} = rec {
    metadata = rec { name = service; labels.app = name; };
    spec = {
      replicas = 1;
      selector.matchLabels = metadata.labels;
      template = {
        metadata.labels = metadata.labels;
        spec = rec {
          hostNetwork = true;
          dnsPolicy = "ClusterFirstWithHostNet";
          nodeSelector."cloud.google.com/gke-nodepool" = ingress-pool;
          tolerations = [{ key = "dedicated"; operator = "Equal"; value = "ingress"; effect = "NoSchedule"; }];
          containers = [
            {
              name = metadata.name;
              image = "nginx";
              ports = [
                { name = "https"; containerPort = 443; hostPort = 443; }
                { name = "http"; containerPort = 80; hostPort = 80; }
              ];
              volumeMounts = [
                { name = volumes [ 0 ].name; mountPath = "/cert"; readOnly = true; }
                {
                  name = volumes [ 1 ].name;
                  mountPath = "/etc/nginx/conf.d/default.conf";
                  subPath = "default.conf";
                  readOnly = true;
                }
              ];
            }
          ];
          volumes = [
            (rec { name = "web-certs"; secret.secretName = name; })
            { name = "nginx-conf"; configMap.name = resource.kubernetes_config_map.${service}.metadata.name; }
          ];
        };
      };
    };
  };
}
