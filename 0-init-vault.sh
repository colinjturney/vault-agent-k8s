#!/bin/bash

# Initialise Vault. Store keys locally FOR DEMO PURPOSES ONLY

vault operator init -key-shares=1 -key-threshold=1 > init-output.txt 2>&1

echo "Unseal: "$(grep Unseal init-output.txt | cut -d' ' -f4) >> vault.txt
echo "Token: "$(grep Token init-output.txt | cut -d' ' -f4) >> vault.txt
rm init-output.txt

# Unseal Vault
vault operator unseal $(cat vault.txt | grep Unseal | cut -f2 -d' ')

# Login to Vault
vault login $(cat vault.txt | grep Token | cut -f2 -d' ')

# Initialise the KV secrets engine at path secret/ and add some secrets there

vault secrets enable -path=secret/ kv

vault kv put secret/myapp/config username=hello password=world
