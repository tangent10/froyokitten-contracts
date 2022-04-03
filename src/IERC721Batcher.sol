// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721Batcher {
  function getURIs(address erc721Address, address user) external view returns(string[] memory);
  function getIds(address erc721Address, address user) external view returns(uint256[] memory);
}
