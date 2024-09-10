{ stdenvNoCC
, makeWrapper
, lib
, deps
}:

stdenvNoCC.mkDerivation rec {
  name = "encryption-utils";
  meta.description = "Peter's encryption scripts";
  dontBuild = true;
  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p \
      "$out/bin" \
      "$out/wrapped" \
      "$out/lib" \
      "$out/share/doc/encryption"

    find bin -type f -exec install -m 0555 '{}' "$out/wrapped" ';'
    find lib -type f -exec install -m 0444 '{}' "$out/lib" ';'
    find doc -type f -exec install -m 0444 '{}' "$out/share/doc/encryption" ';'

    while IFS= read -r -d "" file; do
      makeWrapper \
        "$file" "$out/bin/$(basename "$file")" \
        --prefix PATH : "${lib.makeBinPath deps}"
    done < <(find "$out/wrapped" -type f -print0)
  '';
}
