#!/usr/bin/env bash

#################### Globals
BASEDIR="$HOME/.nc/network_connect"
EXEC='./ncsvc'
####################

man=false
user=''
debug=false
verbose=false
port='4444'
kill=false
certificate_file=''
password_file=''

read -d '' docstring <<EOF
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
    gpg -o password.gpg --cipher-algo AES256 --symmetric
---

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
  echodebug "kill: $kill"
  echodebug "password file: $password_file"
  echodebug "certificate file: $certificate_file"

fi

function startup_vpn {
  echo "Connecting ..."
  cd "$BASEDIR"

  # the password
  password=''
  eval "$(gpg --decrypt password.gpg)"

  if $verbose; then
    echo -n "./ncsvc "
    echo -n "-P $port "
    echo -n "-p *** "
    echo -n "-h vpn-ssl.unitn.it "
    echo -n "-u $user "
    echo -n "-f certificato_vpn-ssl.crt "
    echo    "-r AR-unitn-ldap-ad"
  fi
  sudo $EXEC \
          -P $port \
          -p "$password" \
          -h vpn-ssl.unitn.it \
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

if $kill; then
  shutdown_vpn
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
fi

exit 0