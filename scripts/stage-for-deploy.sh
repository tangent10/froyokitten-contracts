#!/bin/bash


function stagefordeploy()
{
  rm /mnt/c/Temp/deploy/*.sol

  cp ./src/ERC721.sol /mnt/c/Temp/deploy
  cp ./src/FroyoKittens.sol /mnt/c/Temp/deploy
}

stagefordeploy "$@"
