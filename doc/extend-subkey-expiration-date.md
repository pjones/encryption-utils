% Extending the Expiration Date for GPG Subkeys
% Peter J. Jones
% July 2, 2017

# Extending the Expiration Date for GPG Subkeys

If you followed my directions for creating a master key that never
expires, and subkeys that do expire, then you're going to occasionally
need to extend the expiration date of those subkeys before they
expire.

The keys themselves don't expire.  Its the signature on the public key
that expires.  When you change the expiration date on a key what you
are really doing is signing the public key with an expiring signature.
Therefore you only need to distribute a new public key after changing
the expiration date, the private keys are not affected.

## Before Continuing (Important Note 1)

Take a moment to
read [Creating a New OpenPGP Master Key](./new-master-pgp-key.md) to
refresh your memory of how things are setup and what the various
commands in this document do.

## Backups Can Save Your Life (Important Note 2)

Before you begin, make sure you have a backup of the `$GNUPGHOME`
directory and your private subkeys.  After extending the expiration
dates of your keys **take another backup** of these items.

## Booting and Mounting the Keys

(Skip this section if you are not using a secure USB drive to hold
your master key.  You should be though.)

  1. Boot a computer off the OS on the USB drive.  Once booted you can
     log in as `root` without a password.

  2. Use `cryptsetup` to decrypt the partition holding the GnuPG
     files.  With my USB key this was as simple as:

        $ cryptsetup open /dev/sda2 keys
        $ mkdir /mnt/keys
        $ mount /dev/mapper/keys /mnt/keys

  3. Ensure that GnuPG can find its files:

        $ export GNUPGHOME=/mnt/keys/gnupg

## Verify the Keys Are Expiring

Finding the expiration date for all of your keys is as simple as
using:

    $ gpg2 --list-keys

This will also show you the key ID of the master key, which you will
use in the next step.

## Changing the Expiration Date for the Subkeys

Begin by starting a GnuPG shell with the intent to edit your master
key:

    $ gpg2 --edit-key <KEY-ID>

GnuPG should tell you that your secret key is available and this list
the key along with its subkeys.

For each subkey you will select the key by its index (beginning with 1
for the first subkey) and change its expiration date:

    gpg> key <INDEX>
    gpg> expire
    gpg> key <INDEX>

(The second use of the `key` command is to de-select the key.)

Save your changes and exit GnuPG:

    gpg> save

**IMPORTANT:** Back up your keys!

    $ mkdir -p $GNUPGHOME/../backup
    $ tar -C $GNUPGHOME/.. -czf $GNUPGHOME/../backup/$(date +%Y-%m-%d).tar.gz $(basename $GNUPGHOME)

## Updating the Keys on Your Smartcard

That's a misleading heading.  You don't actually need to change
anything with your smartcard after updating the expiration date.

Remember, the smartcard only holds the private keys, and updating the
expiration date only affects the public keys.

## Distributing Your Updated Public Keys

You will need to copy your public key back to your main workstation
and also upload it to a key server for everyone else.

See [Creating a New OpenPGP Master Key](./new-master-pgp-key.md) for
details.
