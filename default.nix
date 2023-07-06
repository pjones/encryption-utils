{ pkgs ? import <nixpkgs> { }
}:

pkgs.stdenvNoCC.mkDerivation rec {
  name = "encryption-utils";
  meta.description = "Peter's encryption scripts";
  phases = [ "unpackPhase" "installPhase" "fixupPhase" ];
  src = ./.;

  installPhase = ''
    mkdir -p $out/bin $out/libexec $out/lib $out/share/doc/encryption $out/share/gnupg

    find bin -type f -exec install -m 0555 '{}' $out/bin ';'
    find libexec -type f -exec install -m 0555 '{}' $out/libexec ';'
    find lib -type f -exec install -m 0444 '{}' $out/lib ';'
    find etc -type f -exec install -m 0444 '{}' $out/share/gnupg ';'
    find doc -type f -exec install -m 0444 '{}' $out/share/doc/encryption ';'

    export gpgAgent=${pkgs.gnupg}/bin/gpg-agent
    export pinentry=${pkgs.pinentry.tty}/bin/pinentry

    while IFS= read -r -d "" file; do
      substituteAllInPlace "$file";
    done < <(find "$out/bin" "$out/libexec" "$out/lib" -type f -print0)
  '';
}
