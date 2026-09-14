#!/usr/bin/bash

KEY_DIRECTORY=/work/keys

mkdir -p $KEY_DIRECTORY
[ -f $KEY_DIRECTORY/master_key ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/master_key -C "deploy master key" -N ""

mkdir -p $KEY_DIRECTORY/users
[ -f $KEY_DIRECTORY/users/alice ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/users/alice -C "alice's key" -N ""
[ -f $KEY_DIRECTORY/users/bob ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/users/bob -C "bob's key" -N ""
[ -f $KEY_DIRECTORY/users/charlie ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/users/charlie -C "charlie's key" -N ""
[ -f $KEY_DIRECTORY/users/david ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/users/david -C "david's key" -N ""
[ -f $KEY_DIRECTORY/users/eve ] || ssh-keygen -t ed25519 -f $KEY_DIRECTORY/users/eve -C "eve's key" -N ""
