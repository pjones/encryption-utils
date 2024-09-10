{ pkgs
, self
}:
pkgs.nixosTest {
  name = "make-usb-drive-test";

  nodes = {
    machine = { pkgs, ... }: {
      imports = [ self.nixosModules.offlineGPG ];
      virtualisation.memorySize = 1024;
      virtualisation.emptyDiskImages = [ 2048 ];
    };
  };

  testScript = ''
    start_all()

    # Run the test script:
    machine.copy_from_host("${./make-usb-drive.sh}", "/tmp/test.sh")
    machine.succeed("bash /tmp/test.sh /dev/vdb")
  '';
}
