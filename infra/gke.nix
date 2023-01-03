{ project, cluster, users, taint }:
rec {
  resource.google_project_service.kubernetes = {
    service = "container.googleapis.com";
  };
  resource.google_container_cluster.${project} = cluster // {
    name = "${project}-cluster";
    remove_default_node_pool = true;
    initial_node_count = 1;
    addons_config.http_load_balancing.disabled = true;
  };
  resource.google_container_node_pool.ingress-pool = {
    name = "ingress-pool";
    cluster = resource.google_container_cluster.${project}.name;
    node_count = 1;
    node_config = [
      {
        machine_type = "e2-micro";
        disk_size_gb = 10;
        taint = [ taint ];
      }
    ];
  };
  resource.google_container_node_pool.web-pool = {
    name = "web-pool";
    cluster = resource.google_container_cluster.${project}.name;
    node_count = 1;
    node_config = [
      {
        preemptible = true;
        machine_type = "e2-medium";
        disk_size_gb = 20;
      }
    ];
  };
  resource.kubernetes_cluster_role_binding.cluster-admin = rec {
    metadata = { name = "cluster-admin-binding"; };
    role_ref = { api_group = "rbac.authorization.k8s.io"; kind = "ClusterRole"; name = "cluster-admin"; };
    subject = map (name: { kind = "User"; inherit (role_ref) api_group; inherit name; }) users;
  };
}
