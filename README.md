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

### CONNECTION MODES

With the option --mode, you can change how traffic is routed through the VPN.

* **split tunnel** mode[3] (--mode=split): the VPN connection provides traffic
  directed to intranet IPs using the VPN tunnel while traffic to other networks
  (e.g Internet) is provided by the standard client connection.
  The IP assigned to the tun interface is in the range:
  10.31.0.10 - 10.31.0.254.
* **out** mode[4] (--mode=out): all the traffic will flow in the SSL tunnel and
  the internet traffic is natted with a UniTN public IP address.
  The IP assigned to the tun interface is in the range:
  10.31.111.10 - 10.31.111.254.


### KNOWN BUGS AND LIMITATIONS

On kernels v. 4.5.5 and later (currently affecting Ubuntu 16.10 and Fedora 24,
among others), a bug[[1]][[2]] causes the VPN to establish wrong routing rules.
A workaround is available running the following command:
```
  echo 0 | sudo tee /proc/sys/net/ipv6/conf/default/router_solicitations
```

#### REFERENCES
[1]: https://bugzilla.redhat.com/show_bug.cgi?id=1343091#c17
[2]: https://askubuntu.com/questions/846053/
[3]: https://wiki.unitn.it/pub:conf-vpn-en
[4]: https://wiki.unitn.it/pub:conf-vpn-out-en

* [[1]]: https://bugzilla.redhat.com/show_bug.cgi?id=1343091#c17
* [[2]]: https://askubuntu.com/questions/846053/
* [[3]]: https://wiki.unitn.it/pub:conf-vpn-en
* [[4]]: https://wiki.unitn.it/pub:conf-vpn-out-en

# LICENSE

```
unitn_vpn_old.sh 0.1.0
copyright (c) 2016 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
```
