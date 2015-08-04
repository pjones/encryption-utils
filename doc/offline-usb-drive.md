# Building an Offline USB Drive

## Introduction

This guide shows how to build a bootable USB thumb drive that also
contains a LUKS encrypted file system.  The idea is that you boot into
a read-only operating system and store your master private key on a
LUKS encrypted partition on the same thumb drive.

## Choose an ISO Image

I've decided to build a NixOS minimal ISO with some additions that
includes `gpg2`.  Any Linux ISO can be used in this process.  Pick one
that includes the software that you'll need.

My minimal ISO can be built by fetching [my NixOS repository]
[pjones-nixos] and using the `gpg-iso` branch.  The details for
building an ISO image are in the `boot/make-usb-drive` script in this
repository.

## Setting Up the USB Drive

  #. Use the `make-encrypted-dev` script in this repository with the
     `-b` and `-d` command-line options.  That will set up a USB stick
     with two partitions.  The first is where you can store the ISO
     and the second is LUKS encrypted and used to store your GnuPG
     keychain.

  #. Put your ISO image on the first partition according to
     [these instructions] [Multiboot USB Drive] and configure Grub.
     Look at the `boot/make-usb-drive` for inspiration.

  #. Boot off the USB stick, mount the second partition, and work with
     GnuPG.  The `make-encrypted-dev` script in this repository can be
     used to help mount the encrypted second partition.

Detailed instructions for setting up a new GnuPG key with this setup
can be found in the [new-master-pgp-key.md](new-master-pgp-key.md)
file.

## References

  * [Building a NixOS ISO] []
  * [Multiboot USB Drive] []

[pjones-nixos]: https://github.com/pjones/nixpkgs/blob/gpg-iso/nixos/modules/installer/cd-dvd/gpg-iso.nix
[building a nixos iso]: http://nixos.org/nixos/manual/sec-building-cd.html
[multiboot usb drive]: https://wiki.archlinux.org/index.php/Multiboot_USB_drive
