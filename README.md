# UniTN VPN utils

`unitn_vpn_old.sh` is a wrapper script to connect to the UniTN "old" VPN.
For further info read [pub:conf-vpn](https://wiki.unitn.it/pub:conf-vpn)
(in Italian).

```
Usage:
  unitn_vpn_old.sh [options] --user USER
  unitn_vpn_old.sh [options] --kill
  unitn_vpn_old.sh ( -h | --help | --man )
  unitn_vpn_old.sh ( --version )

  Options:
    --certificate-file CERT_FILE  Certificate file
                                  [default: $BASEDIR/certificato_vpn-ssl.crt]
    -d, --debug                   Enable debug mode (implies --verbose)
    -k, --kill                    Kill connection
    --port PORT                   Port number [default: 4444]
    --password-file PWD_FILE      Password file
                                  [default: $BASEDIR/password.gpg]
    -s, --status                  Check status
    -u, --user USER               User name.
    -v, --verbose                 Generate verbose output.
    -h, --help                    Show this help message and exits.
    --man                         Show an extended help message.
    --version                     Print version and copyright information.
```

### DEPENDENCIES

This script has the following dependencies:

  * `ncsvc` (`$EXEC`), which should be located in the directory
    `$BASEDIR`, by default `$HOME/.nc/network_connect`.
    For instructions on how to dowload it, read:
    https://wiki.unitn.it/pub:conf-vpn-en (in English)
  * `docopts`, which can be downloaded at:
    https://github.com/docopt/docopts

### CERTIFICATE FILE

You need the certificate file, with the following command you can save
the file  'certificato_vpn-ssl.crt' in \$BASEDIR (which is the default):
```
user@linux:home/user/.nc/network_connect $
openssl s_client -connect vpn-ssl.unitn.it:443 -showcerts < /dev/null 2> /dev/null | \
openssl x509 -outform der > certificato_vpn-ssl.crt
```

### PASSWORD FILE

You need a passoword file, to store your password, the default location is
'password.gpg' in \$BASEDIR.

You can create the encrypted password file with the following command, with
plaintext password 'mypass' (the quotes prevent shell variable substitutions):
```
  echo password=\''mypass'\' | gpg -o password.gpg --cipher-algo AES256 --symmetric
```


# LICENSE

```
unitn_vpn_old.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```
