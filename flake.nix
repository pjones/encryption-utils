{
  description = "Peter's Encryption Utilities and Notes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixos-generators,
      ...
    }:
    let
      # List of supported systems:
      supportedSystems = nixpkgs.lib.platforms.unix;

      # Function to generate a set based on supported systems:
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Attribute set of nixpkgs for each system:
      nixpkgsFor = forAllSystems (
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true; # ventoy is closed now?
        }
      );

      deps = pkgs: [
        pkgs.cryptsetup
        pkgs.file
        pkgs.gnumake
        pkgs.gnupg
        pkgs.libossp_uuid
        pkgs.parted
        pkgs.pinentry-tty
        pkgs.util-linux
        pkgs.yubikey-manager
        pkgs.yubikey-personalization
      ];
    in
    {
      nixosModules = {
        offlineGPG =
          { pkgs, lib, ... }:
          let
            system = pkgs.stdenv.hostPlatform.system;
          in
          {
            environment.systemPackages = deps pkgs ++ [
              self.packages.${system}.encryption-utils
              self.packages.${system}.gpg-prepare
            ];

            # Might be needed:
            hardware.gpgSmartcards.enable = true;
            programs.gnupg.agent.enable = true;

            # Make sure networking is disabled.
            networking.useDHCP = lib.mkForce false;
            networking.useNetworkd = lib.mkForce false;
            networking.networkmanager.enable = lib.mkForce false;
            networking.interfaces = { };
            networking.wireless.enable = lib.mkForce false;
          };
      };

      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = self.packages.${system}.encryption-utils;

          encryption-utils = pkgs.callPackage ./. {
            deps = deps pkgs;
          };

          gpg-prepare = pkgs.writeShellScriptBin "gpg-prepare" (builtins.readFile script/gpg-prepare);

          iso = nixos-generators.nixosGenerate {
            inherit system;
            format = "install-iso";

            modules = [
              self.nixosModules.offlineGPG

              (
                { config, lib, ... }:
                {
                  nixpkgs.pkgs = pkgs;
                  nix.registry.nixpkgs.flake = nixpkgs;
                  networking.hostName = "gpg";
                  system.stateVersion = "25.11";
                  users.users.root.initialHashedPassword = "";
                  isoImage.appendToMenuLabel = " w/ GPG";

                  image.fileName = lib.mkForce (
                    lib.concatStringsSep "-" [
                      config.system.nixos.distroId
                      "gnupg"
                      config.system.nixos.label
                      pkgs.stdenv.hostPlatform.system
                    ]
                    + ".iso"
                  );

                  environment.variables.GNUPGHOME = "/mnt/keys/gnupg";
                  services.getty.helpLine = ''

                    To prepare an environment for GnuPG first run the
                    gpg-prepare command.  You should give it the path to
                    device file for the USB drive that has the encrypted
                    GnuPG partition on it.  For example:

                      gpg-prepare /dev/sda
                  '';
                }
              )
            ];
          };
        }
      );

      overlays = {
        default = final: prev: {
          pjones = (prev.pjones or { }) // {
            encryption-utils = self.packages.${prev.stdenv.hostPlatform.system}.encryption-utils;
          };
        };
      };

      apps = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = {
            type = "app";
            meta.description = "Create a bootable USB drive";
            program = toString (
              pkgs.writeShellScript "mkusb" ''
                ${self.packages.${system}.encryption-utils}/bin/make-encrypted-usb-drive \
                  -i ${self.packages.${system}.iso}/iso/nixos-*.iso \
                  "$@"
              ''
            );
          };
        }
      );

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
          test = file: import file { inherit pkgs self; };
        in
        {
          encrypted-dev = test test/encrypted-dev.nix;
          gpg-new-key = test test/gpg-new-key.nix;
          make-usb-drive = test test/make-usb-drive.nix;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = deps pkgs;
          };
        }
      );
    };
}
