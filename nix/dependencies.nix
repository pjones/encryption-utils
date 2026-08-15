{ ... }:
{
  # Common dependencies needed by all scripts:
  flake.lib.dependencies = pkgs: [
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
}
