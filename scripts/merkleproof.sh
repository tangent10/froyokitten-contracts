#!/bin/bash


function merkleproof()
{
  [ -z "$1" ] && printf 'usage:\n  ./scripts/merkleproof.sh $address\n'
  printf '%s' $(node ./merkle-gen proof "$1")
}

merkleproof "$@"
