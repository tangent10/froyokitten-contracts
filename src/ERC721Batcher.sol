// SPDX-License-Identifier: MIT

import "./ERC721.sol";

pragma solidity ^0.8.0;

contract ERC721Batcher {

  function getURIs(address erc721Address, address user) public view returns(string[] memory) {
    ERC721 nft = ERC721(erc721Address);
    uint256 numTokens = nft.balanceOf(user);
    string[] memory uriList = new string[](numTokens);
    for (uint256 i; i < numTokens; i++) {
      uriList[i] = nft.tokenURI(nft.tokenOfOwnerByIndex(user, i));
    }
    return(uriList);
  }

  function getIds(address erc721Address, address user) public view returns(uint256[] memory) {
    ERC721 nft = ERC721(erc721Address);
    uint256 numTokens = nft.balanceOf(user);
    uint256[] memory uriList = new uint256[](numTokens);
    for (uint256 i; i < numTokens; i++) {
      uriList[i] = nft.tokenOfOwnerByIndex(user, i);
    }
    return(uriList);
  }
}
