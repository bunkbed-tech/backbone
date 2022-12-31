{
  description = "bunkbed backbone infrastructure";
  inputs = {
    devshell.url = "github:numtide/devshell";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/release-22.11";
    terranix.url = "github:terranix/terranix";
    terranix.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{ self
    , devshell
    , flake-utils
    , nixpkgs
    , terranix
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; overlays = [ devshell.overlay ]; };
      inherit (builtins) toString;
      inherit (pkgs.devshell) mkShell;
      inherit (pkgs.lib) genAttrs;
      inherit (pkgs.writers) writeBash;
      inherit (terranix.lib) terranixConfiguration;
      project = "backbone";
      tf = rec {
        config = terranixConfiguration { inherit system; modules = [ ./infra ]; };
        commandToApp = command: {
          type = "app";
          program = toString (writeBash "${command}" ''
            result="infra.tf.json"
            [[ -e $result ]] && rm -f $result
            cp ${config} $result
            terraform init
            terraform ${command}
          '');
        };
      };
    in
    rec {
      packages.tf = tf.config;
      packages.default = packages.tf;

      apps = genAttrs [ "apply" "plan" "destroy" ] tf.commandToApp;

      devShell = mkShell {
        name = "${project}-shell";
        commands = [{ package = "devshell.cli"; }];
        packages = with pkgs; [
          cmctl
          gitleaks
          go
          # Need this extra component in order for kubectl to communicate with GKE cluster
          # For more details, see issue at: https://github.com/NixOS/nixpkgs/issues/99280#issuecomment-1227334798
          (google-cloud-sdk.withExtraComponents ([ google-cloud-sdk.components.gke-gcloud-auth-plugin ]))
          kubectl
          kubernetes-helm
          nixpkgs-fmt
          pre-commit
          terraform
          terranix
          tfsec
        ];
      };
    }
    );
}
