{ self, lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    {
      ##########################################################################
      packages.default = self.packages.${system}.encryption-utils;

      packages.gpg-prepare = pkgs.writeShellScriptBin "gpg-prepare" (
        builtins.readFile ../script/gpg-prepare
      );

      packages.encryption-utils = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        name = "encryption-utils";
        meta.description = "Peter's encryption scripts";
        dontBuild = true;
        src = self;

        nativeBuildInputs = with pkgs; [
          makeWrapper
        ];

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
              --prefix PATH : "${lib.makeBinPath (self.lib.dependencies pkgs)}"
          done < <(find "$out/wrapped" -type f -print0)
        '';
      });

      ##########################################################################
      checks =
        let
          test = file: import file { inherit pkgs self; };
        in
        {
          encrypted-dev = test ../test/encrypted-dev.nix;
          gpg-new-key = test ../test/gpg-new-key.nix;
          make-usb-drive = test ../test/make-usb-drive.nix;
        };
    };
}
