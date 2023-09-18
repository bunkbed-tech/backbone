{ config, lib, pkgs, ... }:
{
  terraform.required_providers.namecheap = { source = "namecheap/namecheap"; version = "2.1.0"; };
  variable.namecheap_api_key = { type = "string"; sensitive = true; };
  variable.namecheap_api_user = { type = "string"; };
  provider.namecheap = {
    api_user = "\${ var.namecheap_api_user }";
    api_key = "\${ var.namecheap_api_key }";
    user_name = "\${ var.namecheap_api_user }";
  };
}
