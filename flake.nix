{
  description = "Bunkbed backbone infrastructure";
  inputs = {
    flake-utils.url = github:numtide/flake-utils;
    nixpkgs.url = github:nixos/nixpkgs;
    terranix.url = github:terranix/terranix;
  };
  outputs =
    inputs@{ self
    , flake-utils
    , nixpkgs
    , terranix
    }: flake-utils.lib.eachDefaultSystem (system:
    let
      overlay = (final: prev: { lib = prev.lib // { backbone = import ./src/lib { pkgs = final; }; }; });
      pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      mk-cluster-terranix = cluster: module: terranix.lib.terranixConfiguration {
        inherit system pkgs;
        modules = [ ./src/cluster ({ kubernetes.context = cluster; }) module ];
      };
    in {
      packages = builtins.mapAttrs mk-cluster-terranix {
        k3d-bunkbed = ./src/k3d.nix;
        sirver-k3s = {};
        sirver-k8s = {};
      };
      devShell = pkgs.mkShell {
        packages = with pkgs; [
          ansible
          bash
          gitleaks
          gnugrep
          go
          k3d
          kubectl
          kubernetes-helm
          openssh
          pre-commit
          shellcheck
          terraform
          tektoncd-cli
        ];
        shellHook = ''
          export PRJ_ROOT="$(git rev-parse --show-toplevel)"
          export PATH="$PRJ_ROOT/bin:$PATH"
        '';
      };
    }
  );
}
