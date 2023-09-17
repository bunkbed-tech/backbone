{
  description = "Bunkbed backbone infrastructure";
  inputs = {
    devshell.url = github:numtide/devshell;
    flake-utils.url = github:numtide/flake-utils;
    nixpkgs.url = github:nixos/nixpkgs;
    terranix.url = github:terranix/terranix;
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
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          devshell.overlay
          (final: prev: { lib = prev.lib // { backbone = import ./infra/lib { pkgs = final; }; }; })
        ];
      };
      x = pkgs.lib.backbone.subTemplateCmds {
        template = ./bin/x;
        cmds.bash = "${pkgs.bash}/bin/bash";
        cmds.terraform = "${pkgs.terraform}/bin/terraform";
        cmds.grep = "${pkgs.gnugrep}/bin/grep";
        cmds.ssh = "${pkgs.openssh}/bin/ssh";
      };
    in {
      packages.k3d-bunkbed = terranix.lib.terranixConfiguration {
        inherit system pkgs;
        modules = [
          ./infra/cluster.nix
          { kubernetes.context = "k3d-bunkbed"; }
        ];
      };
      packages.sirver-k3s = terranix.lib.terranixConfiguration {
        inherit system pkgs;
        modules = [
          ./infra/cluster.nix
          { kubernetes.context = "sirver-k3s"; }
        ];
      };
      packages.sirver-k8s = terranix.lib.terranixConfiguration {
        inherit system pkgs;
        modules = [
          ./infra/cluster.nix
          { kubernetes.context = "sirver-k3s"; }
        ];
      };
      packages.default = self.packages.${system}.k3d-bunkbed;

      apps.default = self.outputs.devShells.${system}.default.flakeApp;

      devShell = pkgs.devshell.mkShell ({ ... }: {
        name = "BACKBONE";
        commands = [ { name = "x"; command = x; } ];
        packages = with pkgs; [
          bash
          gitleaks
          gnugrep
          go
          k3d
          kubectl
          kubernetes-helm
          nixpkgs-fmt
          openssh
          pre-commit
          shellcheck
          terraform
          terraform-docs
          terranix
          tfsec
        ];
      });
    }
  );
}
