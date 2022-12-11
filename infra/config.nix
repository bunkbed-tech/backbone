{ config, lib, pkgs, ... }:
let
  org = "bunkbed";
  project = "backbone";
in
{

  # TERRAFORM CONFIG
  terraform.backend.gcs = {
    bucket = "${org}-terraform";
    prefix = "${project}/state";
  };

  # EXISTING RESOURCES
  # NEW RESOURCES
}
