{ pkgs
, self
}:
pkgs.nixosTest {
  name = "gpg-new-key-test";

  nodes = {
    machine = { pkgs, ... }: {
      imports = [ self.nixosModules.offlineGPG ];
      virtualisation.emptyDiskImages = [ 512 ];
    };
  };

  testScript = ''
    start_all()
    machine.succeed("mkdir -p /mnt")

    # Run the test script:
    machine.copy_from_host("${./gpg-new-key.sh}", "/tmp/test.sh")
    machine.succeed("bash /tmp/test.sh")
  '';
}
