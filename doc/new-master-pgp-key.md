# Creating a New OpenPGP Master Key

## Introduction

This document describes how to create a new OpenPGP master key and
subkeys.  It assumes you are doing this on an offline computer via a
LiveCD/ISO that includes `GnuPG` version 2.  These instructions are
mostly based on an [article by Simon Josefsson] [josefsson].

## Motivation

I wanted to get a bit more serious about using OpenPGP for encrypting
sensitive documents, email, and passwords.  I also wanted to be able
to perform these operations on mobile devices without taking on
additional risk of exposing sensitive data if a device is stolen or
lost.

## Overview of Keys and Subkeys

Following this document, you will create:

  #. A master OpenPGP private key that can only be used for signing.
     This key will not expire.  If this key is compromised an
     expiration date won't help since the attacker can just change the
     date.

     This key will therefore be kept offline and secure.  Never expose
     this key to your daily working computers or devices.  That's why
     I build a special Linux ISO image for booting a secure computer
     offline and running the commands described in this document.

  #. A private subkey that can be used for signing.  This key will
     expire in two years.  This key will be used solely for creating
     signatures.  The only thing it can't be used for is signing
     public keys.  For that you'll need to use the master key.

  #. A private subkey that can be used for encryption.  This key will
     expire in two years.  This is the key that you'll use to access
     files encrypted with your public key.

  #. A private subkey that can be used for authentication.  This key
     will expire in two years.  I'm not using this key right now but
     hope to use it for SSH authentication soon.

  #. A public key that will contain the public portion of the master
     signing key, and the public portions of all the subkeys.

If any of the subkeys are compromised, the master key can be used to
revoke them and generate new subkeys.

All of the above keys will only exist on your secure, offline
computer.  Your private subkeys will be uploaded to a smartcard and
then removed from your private keychain (but retained in a secure
backup).

Therefore, on your daily machines and devices, you'll only have the
following:

  * Public key (master and subkeys).

  * Stubs for the private subkeys.  You'll need to have the smartcard
    in order to work with the private subkeys.

## Preparation

  #. Build a USB stick where you can boot into an offline Linux
     distribution and access an encrypted partition.  I describe my
     setup in the [offline-usb-drive.md](offline-usb-drive.md) file.

  #. Mount the encrypted partition using `cryptsetup` (or using the
     `mount-encrypted-dev` script included in this repository).  This
     document assumes you have it mounted on `/mnt/keys`.

### Creating the Master Key

  #. Tell GnuPG where to store files:

        $ export GNUPGHOME=/mnt/keys/gnupg
        $ mkdir -p $GNUPGHOME

  #. Generate a new key:

        $ gpg2 --gen-key

     - Create a `RSA (sign only)` key.
     - Set the keysize to `4096`
     - Don't configure an expiration date for the key

  #. Optionally add another identity to the key:

        $ gpg2 --edit-key <new-key-ID>

        gpg> adduid
        gpg> uid 1
        gpg> primary
        gpg> save

  #. Create a revocation certificate:

        $ gpg2 --output $GNUPGHOME/revoke-cert.txt --gen-revoke <new-key-ID>

  #. Create subkeys for signing, encrypting, and authentication:

        $ gpg2 --expert --edit-key <new-key-ID>

        gpg> addkey
        gpg> addkey
        gpg> addkey
        gpg> save

     - First create a `RSA (sign only)` key
     - Then create a `RSA (encrypt only)` key
     - Finally, create a `RSA (set your own capabilities)`, disable
       signing and encrypting, and then enable authentication
     - The key sizes need to be `2048`
     - Set the keys to expire in 2 years

  #. **Backup your subkeys**

     Transferring the subkeys to a smartcard is a destructive
     operation.  Make sure you backup your keys and entire `GNUPGHOME`
     before continuing.

        $ mkdir -p $GNUPGHOME/../backup
        $ tar -C $GNUPGHOME/.. -czf $GNUPGHOME/../backup/$(date +%Y-%m-%d).tar.gz $(basename $GNUPGHOME)
        $ gpg2 -a --export-secret-subkeys <keyID> > $GNUPGHOME/../backup/subkeys.txt

     **NOTE:** According to the `gpg2` man page, using the
     `--export-secret-subkeys` command will take your private subkeys
     offline (i.e. remove them from `$GNUPGHOME`).  Another really
     good reason to have these backups.

     When listing your subkeys, if the key type of `ssb` has a hash
     symbol (`#`) after it, the key is offline.  You can either import
     you keys from the `subkeys.txt` backup file or restore the
     tarball.

## Transferring Subkeys to a Yubikey

  #. Prepare the Yubikey:

        $ ykpersonalize -m82

  #. Configure the OpenPGP Applet

        $ gpg2 --card-edit

        gpg/card> admin
        gpg/card> passwd
        gpg/card> name
        gpg/card> lang
        gpg/card> sex
        gpg/card> login
        gpg/card> url
        gpg/card>
        gpg/card> quit

     - Change the PIN (default `123456`) and Admin PIN (default `12345678`)
     - Set owner information

  #. If you don't want to require a PIN entry for *every* signing
     request then toggle the "Signature PIN: forced" setting:

         $ gpg2 --card-edit

         gpg/card> admin
         gpg/card> forcesig
         gpg/card> list

  #. Move keys to the smartcard:

        $ gpg2 --edit-key <keyID>

        gpg> toggle
        gpg> key 1
        gpg> keytocard
        gpg> ...
        gpg> save

     - Continue selecting keys and using the `keytocard` command.

  #. Confirm the keyring no longer has the secret subkeys

     When listing the keys, the subkeys should be listed with a
     greater than symbol after the key type (i.e. `ssb>`) to indicate
     they are not present.

        $ gpg --list-secret-keys <keyID>

## Moving the Public Key to a Daily Machine

  #. Backup everything we have so far:

        $ gpg2 -a --output $GNUPGHOME/../backup/subkeystubs.txt --export-secret-subkeys <keyID>
        $ gpg2 -a --output $GNUPGHOME/../backup/public.txt --export <keyID>

  #. Transfer to another machine and import the public key:

        $ gpg2 --import < public.txt

  #. Insert the Yubikey and create the subkey stubs:

        $ gpg2 --card-status

  #. Mark the key as trusted (ultimate):

        $ gpg2 --edit-key <keyID>

        gpg> trust
        gpg> quit

(Consider uploading your key to a key server with `gpg2 --send-keys <KEY-ID>`.)

## Make Backups

Please, for the love of everything that is holy, clone your USB drive,
and make sure you have copies of your private subkeys somewhere safe
and secure.

## References

  * [Article by Simon Josefsson] [josefsson]

  * The GnuPG manual and HOWTO documents.

[josefsson]: http://blog.josefsson.org/2014/06/23/offline-gnupg-master-key-and-subkeys-on-yubikey-neo-smartcard/
