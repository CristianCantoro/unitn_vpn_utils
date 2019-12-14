#!/usr/bin/env bash

#################### Globals
BASEDIR="$HOME/.nc/network_connect"
EXEC='./ncsvc'
####################

man=false
user=''
debug=false
verbose=false
mode='split'
port='4444'
kill=false
certificate_file=''
password_file=''

read -rd '' docstring <<EOF
Usage:
  unitn_vpn_old.sh [options] [ --mode split | --mode out ] --user USER
  unitn_vpn_old.sh [options] --kill
  unitn_vpn_old.sh ( -h | --help | --man )
  unitn_vpn_old.sh ( --version )

  Options:
    --certificate-file CERT_FILE  Certificate file
                                  [default: $BASEDIR/certificato_vpn-ssl.crt]
    -d, --debug                   Enable debug mode (implies --verbose)
    -k, --kill                    Kill connection
    --mode ( split | out )        Switch VPN mode: 'split' is the split-tunnel
                                  mode and routes only the traffic directed to
                                  the resources within the VPN, 'out' routes
                                  all traffic through the VPN.
                                  Existing connection do not get rerouted.
                                  [default: split]
    --port PORT                   Port number [default: 4444]
    --password-file PWD_FILE      Password file
                                  [default: $BASEDIR/password.gpg]
    -s, --status                  Check status
    -u, --user USER               User name.
    -v, --verbose                 Generate verbose output.
    -h, --help                    Show this help message and exits.
    --man                         Show an extended help message.
    --version                     Print version and copyright information.
----
unitn_vpn_old.sh 0.1.0
copyright (c) 2015 Cristian Consonni
MIT License
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
EOF

eval "$(echo "$docstring" | docopts -V - -h - : "$@" )"

# bash strict mode
# See:
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'


#################### Utils
echodebug() { echo -en "[$(date '+%F_%k:%M:%S')][debug]\t"; echo "$@" 1>&2; }

bold()          { ansi 1 "$@"; }
italic()        { ansi 3 "$@"; }
underline()     { ansi 4 "$@"; }
strikethrough() { ansi 9 "$@"; }
ansi()          { echo -e "\e[${1}m${*:2}\e[0m"; }
####################


#################### Documentation helpers

function print_help() {
  eval "$(echo "$docstring" | docopts -V - -h - : '-h' | head -n -1)"
}

function print_man() {

  print_help

  echo -e "$(cat <<MANPAGE

$(bold DEPENDENCIES)

This script has the following dependencies:

  * '$(basename $EXEC)' (\$EXEC), which should be located in the directory
    '$BASEDIR' (\$BASEDIR),
    by default \$HOME/.nc/network_connect.
    For instructions on how to dowload it, read:
    https://wiki.unitn.it/pub:conf-vpn-en
  * 'docopts', which can be downloaded at:
    https://github.com/docopt/docopts

$(bold CERTIFICATE\ FILE)

You need the certificate file, with the following command you can save
the file  'certificato_vpn-ssl.crt' in \$BASEDIR (which is the default):
---
  user@linux:home/user/.nc/network_connect $
    openssl s_client -connect vpn-ssl.unitn.it:443 -showcerts < /dev/null \ 
      2> /dev/null | openssl x509 -outform der > certificato_vpn-ssl.crt
---

$(bold PASSWORD\ FILE)

You need a passoword file, to store your password, the default location is
'password.gpg' in \$BASEDIR.

You can create the encrypted password file with the following command, with
plaintext password 'mypass' (the quotes prevent shell variable substitutions):
---
  echo password=\''mypass'\' | \ 
    /usr/bin/gpg2 -o password.gpg --cipher-algo AES256 --symmetric
---

$(bold CONNECTION\ MODES)

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

$(bold KNOWN\ BUGS\ AND\ LIMITATIONS)

On kernels v. 4.5.5 and later (currently affecting Ubuntu 16.10 and Fedora 24,
among others), a bug[1][2] causes the VPN to establish wrong routing rules.
A workaround is available running the following command:
---
  echo 0 | sudo tee /proc/sys/net/ipv6/conf/default/router_solicitations
---

REFERENCES

[1]: https://bugzilla.redhat.com/show_bug.cgi?id=1343091#c17
[2]: https://askubuntu.com/questions/846053/
[3]: https://wiki.unitn.it/pub:conf-vpn-en
[4]: https://wiki.unitn.it/pub:conf-vpn-out-en

MANPAGE
)"

}

if $man; then
  print_man
  exit 0
fi


# --debug implies --verbose
if $debug; then
  verbose=true
fi

if $debug; then
  echodebug "BASEDIR: $BASEDIR"
  echodebug "EXEC: $EXEC"
  echodebug "---"
  echodebug "user: $user"
  echodebug "port: $port"
  echodebug "mode: $mode"
  echodebug "kill: $kill"
  echodebug "password file: $password_file"
  echodebug "certificate file: $certificate_file"

fi

if [[ "$mode" != 'split' && "$mode" != 'out' ]]; then
  (>&2 echo '---')
  (>&2 echo "Error: option --mode required either 'split' or 'out' as arguments")
  (>&2 echo 'Usage:')
  (>&2 echo -e '\tunitn_vpn_old.sh [options] [--mode split | --mode out] --user USER')
  exit 1
fi

function startup_vpn {
  local host_net='vpn-ssl.unitn.it'
  local ive_mode_url

  echo "Connecting ..."
  cd "$BASEDIR"

  # the password
  local password=''
  eval "$(/usr/bin/gpg2 --decrypt password.gpg || echo 'false')"

  ive_mode_url='https://vpn-ssl.unitn.it'
  if [[ "$mode" == 'split' ]]; then
    # mode is 'split'
    echodebug 'VPN is in split-tunnel mode'
  else
    # mode is 'out'
    echodebug 'VPN is in out mode'

    ive_mode_url='vpn-ssl.unitn.it/vpn-out'
  fi

  if $verbose; then
    echo -n "./ncsvc "
    echo -n "-P $port "
    echo -n "-p *** "
    echo -n "-h $host_net "
    echo -n "-U $ive_mode_url "
    echo -n "-u $user "
    echo -n "-f certificato_vpn-ssl.crt "
    echo    "-r AR-unitn-ldap-ad"
  fi

  sudo $EXEC \
          -P $port \
          -p "$password" \
          -h "$host_net" \
          -U "$ive_mode_url" \
          -u $user \
          -f certificato_vpn-ssl.crt \
          -r AR-unitn-ldap-ad
  sleep 0.5
  pidof $EXEC > "$BASEDIR/pid"
}

function shutdown_vpn {
  echo "Shutting down VPN"
  cd "$BASEDIR"
  sudo $EXEC -Kill

  rm -f "$BASEDIR/pid"
}

# define cleanup function to be executed on exit
function finish {
  shutdown_vpn
}
trap finish EXIT

if $kill; then
  # it is not necessary to call shutdown_vpn because it will be called by
  # the exit trap
  exit 0
fi

if [ ! -f "$BASEDIR/pid" ]; then

  if [[ ! $user ]]; then
    (>&2 echo '---')
    (>&2 echo 'Error: option --user is required to start the VPN')
    (>&2 echo 'Usage:')
    (>&2 echo -e '\tunitn_vpn_old.sh [options] --user username@unitn.it')
    exit 1
  fi
  echo "Connecting with user: $user"
  startup_vpn $user

else
  (>&2 echo '---')
  (>&2 echo "Error: pidfile in '$BASEDIR/pid', is the VPN already active?")
  (>&2 echo 'If you need to stop it launch:')
  (>&2 echo -e '\tunitn_vpn_old.sh --kill')
  (>&2 echo 'however, the VPN should be shut down now.')
fi

exit 0