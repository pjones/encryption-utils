{ self, ... }:
{
  perSystem = { pkgs, system, ... }: {
    devShells.default = pkgs.mkShell {
      inputsFrom = builtins.attrValues self.packages.${system};
    };
  };
}
