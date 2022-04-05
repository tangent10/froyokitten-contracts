#!/bin/bash


function merkleroot()
{
  printf '%s' $(node ./merkle-gen root)
}

merkleroot "$@"
