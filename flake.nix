{
  description = "Peter's Encryption Utilities and Notes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs, ... }:
    let
      # List of supported systems:
      supportedSystems = nixpkgs.lib.platforms.unix;

      # Function to generate a set based on supported systems:
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
    in
    {
      packages = forAllSystems (system: {
        encryption-utils = import ./. { pkgs = nixpkgsFor.${system}; };
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.encryption-utils);

      overlay = final: prev: {
        pjones = (prev.pjones or { }) //
          { encryption-utils = self.packages.${prev.system}.encryption-utils; };
      };
    };
}
