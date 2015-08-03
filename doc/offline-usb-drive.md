# Building an Offline USB Drive

## Introduction

This guide shows how to build a bootable USB thumb drive that also
contains a LUKS encrypted file system.  The idea is that you boot into
a read-only operating system and store your master private key on a
LUKS encrypted partition on the same thumb drive.

## Choose an ISO Image

I've decided to build a NixOS minimal ISO with some additions that
include `gpg2`.  Any Linux ISO can be used in this process.  Pick one
that includes the software that you'll need.

My minimal ISO can be built by fetching [my NixOS repository]
[pjones-nixos] and using the `gpg-iso` branch.  The details for
building an ISO image are in the `boot/make-usb-drive` script in this
repository.

## Setting Up the USB Drive

Follow the [multiboot USB drive] [] instructions.

## Setting Up the LUKS Partition

FIXME

## References

  * [Building a NixOS ISO] []
  * [Multiboot USB Drive] []

[pjones-nixos]: FIXME
[building a nixos iso]: http://nixos.org/nixos/manual/sec-building-cd.html
[multiboot usb drive]: https://wiki.archlinux.org/index.php/Multiboot_USB_drive
