{
  description = "Peter's Encryption Utilities and Notes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-generators, nixos-hardware, ... }:
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
      nixosModules = {
        offlineGPG = { pkgs, ... }: {
          system.stateVersion = "23.05";
          isoImage.appendToMenuLabel = " w/ GPG";

          environment.systemPackages = [
            pkgs.cryptsetup
            pkgs.file
            pkgs.gnumake
            pkgs.gnupg
            pkgs.libossp_uuid
            pkgs.parted
            pkgs.pinentry.tty
            pkgs.yubikey-manager
            pkgs.yubikey-personalization
            self.packages.${pkgs.system}.encryption-utils
          ];

          # Might be needed:
          hardware.gpgSmartcards.enable = true;

          # Make sure networking is disabled.
          networking.useDHCP = false;
          networking.useNetworkd = false;
          networking.networkmanager.enable = false;
          networking.interfaces = { };
          networking.wireless.enable = false;
        };
      };

      packages = forAllSystems (system: {
        encryption-utils = import ./. { pkgs = nixpkgsFor.${system}; };

        iso = nixos-generators.nixosGenerate {
          format = "install-iso";
          system = "x86_64-linux";
          modules = [
            nixos-hardware.nixosModules.framework-12th-gen-intel
            self.nixosModules.offlineGPG
          ];
        };
      });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.encryption-utils);

      overlay = final: prev: {
        pjones = (prev.pjones or { }) //
          { encryption-utils = self.packages.${prev.system}.encryption-utils; };
      };
    };
}
