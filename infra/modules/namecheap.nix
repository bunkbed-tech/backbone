{ config, lib, pkgs, ... }:
let makeRecords = ip: map (h: { hostname = h; type = "A"; address = ip; }) [ "@" "*" ];
in {
  terraform.required_providers.namecheap = { source = "namecheap/namecheap"; version = "2.1.0"; };
  variable.namecheap_api_key = { type = "string"; };
  variable.namecheap_api_user = { type = "string"; };
  provider.namecheap = rec {
    api_user = "\${ var.namecheap_api_user }";
    api_key = "\${ var.namecheap_api_user }";
    user_name = api_user;
  };
  # resource.namecheap_domain_records.dns = {
  #   domain = "bunkbed.tech";
  #   mode = "MERGE";
  #   record = lib.lists.concatMap makeRecords [];
  # };
}
