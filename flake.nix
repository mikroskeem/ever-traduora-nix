{
  description = "ever-traduora-nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems
      (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        rec {
          packages.esbuild-0_14_24 = pkgs.callPackage ./esbuild-0_14_24.nix { };
          packages.ever-traduora-api = pkgs.callPackage ./default.nix { esbuild = packages.esbuild-0_14_24; };
          packages.ever-traduora-web = packages.ever-traduora-api.web;

          defaultPackage = packages.ever-traduora-api;
        })
    // rec {
      nixosModules.ever-traduora = import ./module.nix;
      nixosModule = nixosModules.ever-traduora;
    };
}
