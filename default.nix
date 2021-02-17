{ pkgs ? import <nixpkgs> { }
}:

pkgs.stdenvNoCC.mkDerivation rec {
  name = "encryption-utils";
  meta.description = "Peter's encryption scripts";
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  src = ./.;

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/gnupg
    find bin boot -type f -exec install -m 0555 '{}' $out/bin ';'
    find lib -type f -exec install -m 0444 '{}' $out/lib ';'
    find etc -type f -exec install -m 0444 '{}' $out/share/gnupg ';'
  '';
}
