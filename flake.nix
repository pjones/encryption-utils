{
  description = "Peter's Encryption Utilities and Notes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
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
          networking.hostName = "gpg";
          system.stateVersion = "24.05";
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
          programs.gnupg.agent.enable = true;

          # Make sure networking is disabled.
          networking.useDHCP = false;
          networking.useNetworkd = false;
          networking.networkmanager.enable = false;
          networking.interfaces = { };
          networking.wireless.enable = false;

          # Create a user with sudo access:
          users.users.nixos = {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            initialHashedPassword = "";
          };

          # Allow sudo without a password:
          security.sudo = {
            enable = true;
            wheelNeedsPassword = false;
          };

          services.getty.autologinUser = "nixos";
          users.users.root.initialHashedPassword = "";
        };
      };

      packages = forAllSystems (system: {
        encryption-utils = import ./. { pkgs = nixpkgsFor.${system}; };

        iso = nixos-generators.nixosGenerate {
          inherit system;

          format = "iso";
          specialArgs.pkgs = nixpkgsFor.${system};

          modules = [
            ({ config, lib, pkgs, ... }: {
              nix.registry.nixpkgs.flake = nixpkgs;
              isoImage.isoName = lib.concatStringsSep "-" [
                config.system.nixos.distroId
                "gnupg"
                config.system.nixos.label
                pkgs.stdenv.hostPlatform.system
              ] + ".iso";
            })
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
