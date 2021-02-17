{ pkgs ? import <nixpkgs> { }
}:
pkgs.nixosTest {
  name = "encryption-utils-test";

  nodes = {
    machine = { pkgs, ... }: {
      virtualisation.memorySize = 1024;
      virtualisation.emptyDiskImages = [ 512 512 ];

      environment.systemPackages = [
        pkgs.utillinux
        pkgs.cryptsetup
        pkgs.parted

        (import ../. { inherit pkgs; })
      ];
    };
  };

  testScript = ''
    start_all()
    machine.succeed("mkdir -p /mnt")

    # Single partition device:
    machine.succeed("make-encrypted-dev -k /etc/issue -! /dev/vdb")
    machine.succeed("mount-encrypted-dev -k /etc/issue /dev/vdb1 /mnt")
    machine.succeed("mountpoint /mnt")
    machine.succeed("mount-encrypted-dev -u /mnt")
    machine.fail("mountpoint /mnt")

    # Dual partition device:
    machine.succeed("make-encrypted-dev -k /etc/issue -! -s 32 /dev/vdc")

    machine.succeed("mount /dev/vdc1 /mnt")
    machine.succeed("mountpoint /mnt")
    machine.succeed("umount /mnt")
    machine.fail("mountpoint /mnt")

    machine.succeed("mount-encrypted-dev -k /etc/issue /dev/vdc2 /mnt")
    machine.succeed("mountpoint /mnt")
    machine.succeed("mount-encrypted-dev -u /mnt")
    machine.fail("mountpoint /mnt")

    # Disk image:
    machine.succeed("make-encrypted-disk-image -k /etc/issue -b 32M test.img")
    machine.succeed("mount-encrypted-dev -k /etc/issue test.img /mnt")
    machine.succeed("mountpoint /mnt")
    machine.succeed("mount-encrypted-dev -u /mnt")
    machine.fail("mountpoint /mnt")
  '';
}
