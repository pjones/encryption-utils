# Utilities and Tutorials for Encryption Tasks

This repository contains utility scripts for automating tasks related
to encryption.  It also contains tutorials/documentation for some of
these tasks (e.g., creating new OpenPGP keys).

## Tutorials/Documentation

  * [Creating a New OpenPGP Master Key](doc/new-master-pgp-key.md)

  * [Building an Offline USB Drive](doc/offline-usb-drive.md)

## Utilities

  * `bin/make-encrypted-dev`: Prepare removable drives and disk
    images, then create LUKS encrypted file systems on them.

  * `bin/mount-encrypted-dev`: Mount (and ummount) devices/images
    created by the `make-encrypted-dev` script.

  * `boot/make-usb-drive`: Create a USB stick with two partitions.
     Generate a [NixOS] [] ISO image and place it on the first
     partition.  Then LUKS encrypt the second partition.  The NixOS
     ISO image includes GnuPG and related tools.

[nixos]: http://nixos.org/
