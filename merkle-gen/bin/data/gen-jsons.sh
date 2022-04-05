#!/bin/bash


source ~/profiles/dapptools.profile

function gen_address_set()
{
  min=$1
  max=$2
  name=$3
  echo '[' > $name.json
  for i in $(seq $min $max)
  do
    if [ $i -eq $max ]
    then
      printf '"%s"\n' $(sethaddy $i) >> $name.json
    else
      printf '  "%s",\n' $(sethaddy $i) >> $name.json
    fi
  done
  echo ']' >> $name.json
}

gen_address_set  1  10 a
gen_address_set 11 20 b
gen_address_set 21 30 c
gen_address_set 31 40 d
gen_address_set 41 50 e

