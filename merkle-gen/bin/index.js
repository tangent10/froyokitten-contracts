#!/usr/bin/env node

const { ethers } = require('ethers')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')
const entries = require('./all.json')
// const entries = require('./three.json')

merkleTree=null

function run(args) {
  merkleTree = new MerkleTree(entries.map(keccak256), keccak256, { sortPairs: true })

  switch(args[0]) {
    case 'r':
    case 'root': {
      console.log(merkleTree.getHexRoot())
      break;
    }
    case 'p':
    case 'proof': {
      if(!(!!args[1])) {
        console.log(`missing claimer address`)
        return
      }
      console.log(merkleTree.getHexProof(keccak256(args[1])))
      break;
    }

    case 't':
    case 'tree': {
      console.log(merkleTree.toString())
      break;
    }

    case 'tj':
    case 'tree-json': {
      console.log(JSON.stringify(merkleTree))
      break;
    }

    case 'l':
    case 'leaf': {
      console.log(keccak256(args[1]).toString('hex'))
      break;
    }

    case 'v':
    case 'verify':
      if(args.length < 2) {
        console.log('missing claimant address to verify')
        return
      }
      const address = args[1]
      const proof = merkleTree.getHexProof(keccak256(address))
      console.log(proof)
      console.log(merkleTree.verify( proof, address, merkleTree.getHexRoot()))
      break;

    case 'h':
    case 'help': {
      printHelp();
      break;
    }

    default:
      printHelp();
      break;
  }
}

function printHelp() {
  console.log('r  | root')
  console.log('p  | proof')
  console.log('pc | proof-count')
  console.log('a  | addy | address | account')
  console.log('t  | tree')
  console.log('l  | leaf')
  console.log('h  | help')
}

const args = process.argv.slice(2)
run(args)


// utils
function printProof(arr) {
  if(!(!!arr)) {
    console.log('ERR : empty arr for proof!!')
    return
  }
  output="[ "
  for(let i = 0; i < arr.length; i++) {
    output=`${output} ${arr[i]}`
    if(i == arr.length - 1) {
      output=`${output} ]`
    } else {
      output=`${output} , `
    }
  }
  return output
}

// TODO: debug, remove
// console.log(`0x82eCCdC1C959dFe1C9e51334C043B9c289bC6cFb <> ${entries[735]}`)
