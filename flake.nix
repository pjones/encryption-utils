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

      deps = pkgs: [
        pkgs.cryptsetup
        pkgs.file
        pkgs.gnumake
        pkgs.gnupg
        pkgs.libossp_uuid
        pkgs.parted
        pkgs.pinentry.tty
        pkgs.util-linux
        pkgs.ventoy
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
      ];
    in
    {
      nixosModules = {
        offlineGPG = { pkgs, ... }: {
          environment.systemPackages = deps pkgs ++ [
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
        };
      };

      packages = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = self.packages.${system}.encryption-utils;

          encryption-utils = pkgs.callPackage ./. {
            deps = deps pkgs;
          };

          iso = nixos-generators.nixosGenerate {
            inherit system;

            format = "iso";
            specialArgs.pkgs = nixpkgsFor.${system};

            modules = [
              ({ config, lib, pkgs, ... }: {
                nix.registry.nixpkgs.flake = nixpkgs;
                networking.hostName = "gpg";
                system.stateVersion = "24.05";
                users.users.root.initialHashedPassword = "";
                isoImage.appendToMenuLabel = " w/ GPG";
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

      overlays = {
        default = final: prev: {
          pjones = (prev.pjones or { }) //
            { encryption-utils = self.packages.${prev.system}.encryption-utils; };
        };
      };

      apps = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = {
            type = "app";
            program = toString (pkgs.writeShellScript "mkventoyusb" ''
              ${self.packages.${system}.encryption-utils}/bin/make-encrypted-usb-drive \
                -i ${self.packages.${system}.iso}/iso/nixos-*.iso \
                "$@"
            '');
          };
        });

      checks = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          test = file: import file { inherit pkgs self; };
        in
        {
          encrypted-dev = test test/encrypted-dev.nix;
          gpg-new-key = test test/gpg-new-key.nix;
          make-usb-drive = test test/make-usb-drive.nix;
        });

      devShells = forAllSystems (system:
        let pkgs = nixpkgsFor.${system}; in {
          default = pkgs.mkShell {
            buildInputs = deps pkgs;
          };
        });
    };
}
