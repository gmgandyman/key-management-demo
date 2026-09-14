#!/usr/bin/bash

# This is only here because WSL cannot actually set linux permissions on files
# This assumes you've created private keys at these locations per named after their users

chmod 0700 keys/users
chmod 0600 keys/users/alice
chmod 0600 keys/users/bob
chmod 0600 keys/users/charlie
chmod 0600 keys/users/david
chmod 0600 keys/users/eve
