{
  self,
  inputs,
  moduleWithSystem,
  withSystem,
  ...
}:
{

  ##############################################################################
  flake.nixosModules.offline = moduleWithSystem (
    { pkgs, system, ... }:
    { lib, ... }:
    {
      # FIXME: silence warning in NixOS 26.05:
      boot.zfs.forceImportRoot = false;

      environment.systemPackages = self.lib.dependencies pkgs ++ [
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
      networking.hostName = "gpg";

      environment.variables.GNUPGHOME = "/mnt/keys/gnupg";
      services.getty.helpLine = ''

        To prepare an environment for GnuPG first run the `gpg-prepare`
        command.  You should give it the path to device file for the USB drive
        that has the encrypted GnuPG partition on it.  For example:

          gpg-prepare /dev/sda

        Then you can run tools like `gpg-new-key.sh` or `gpg-extend-key.sh`.
      '';
    }
  );

  ##############################################################################
  perSystem =
    { pkgs, system, ... }:
    let
      nixosConfig = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          self.nixosModules.offline
          { nixpkgs.pkgs = withSystem system ({ pkgs, ... }: pkgs); }
        ];
      };
    in
    {
      packages.iso = nixosConfig.config.system.build.images.iso-installer;

      apps.mkusb = {
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
    };
}
