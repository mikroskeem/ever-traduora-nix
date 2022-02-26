{
  description = "eteu-ever-traduora";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/master";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    let
      supportedSystems = [
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-linux"
        "x86_64-darwin"
      ];
    in
    flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      rec {
        packages.esbuild-0_14_24 = pkgs.callPackage ./esbuild-0_14_24.nix { };
        packages.ever-traduora-api = pkgs.callPackage ./default.nix { esbuild = packages.esbuild-0_14_24; };
        packages.ever-traduora-web = packages.ever-traduora-api.web;

        defaultPackage = packages.ever-traduora-api;

        nixosModules.ever-traduora = import ./module.nix;
        nixosModule = nixosModules.ever-traduora;
      });
}
