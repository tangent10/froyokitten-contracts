#!/bin/bash

source .sethrc

function froyos_deploy()
{
  file_addresses=./scripts/addresses.json
  dapp build
  dapp create FroyoKittens '"ipfs://base-uri/"'
  ADDRESS_FROYOS=$(getContractAddress)
  echo "{ \"froyoverse\": \"$ADDRESS_FROYOS\" }" > $file_addresses

  # seth send $(address froyoverse) 'setMerkleRoot(bytes32)' "$(node merkle-gen r)"
  printf 'SKIPPING MERKLE ROOT SETTING FOR NOW [2022-03-07 Mon 01:47:01]\n'

  echo "set merkle root"
}

froyos_deploy "$@"
