# Spare Yubikey/SmartCard as a Backup

If you have multiple smartcards you can use one of them as a backup.
Simply put the keys on the smartcard using the same procedure as
creating a [new key](new-pgp-key.md).  Note: you'll need to restore the
backup of your subkeys so they are present on the keyring and can be
transferred to the smartcard.

## Teaching GnuPG to Use a Backup

GnuPG stores the smartcard's serial number in its database and
associates it with the private keys.  In order to get it to start
using the backup smartcard you have to force it to "learn" the serial
number for the inserted smart card:

```
$ gpg-connect-agent "scd serialno" "learn --force" /bye
```
