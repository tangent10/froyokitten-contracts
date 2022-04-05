// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract FroyoKittens is ERC721, Ownable {

  //---------------------------------------------------------------
  //  CONSTANTS
  //---------------------------------------------------------------
  uint256 public constant MAX_SUPPLY = 10000;
  uint256 public constant NFT_PRICE = 0.1 ether;
  uint256 public constant WHITELIST_PRICE = 0.1 ether;
  uint256 public mintStartTime;
  bool    public isRevealed;

  //---------------------------------------------------------------
  //  METADATA
  //---------------------------------------------------------------
  string public baseURI;

  function tokenURI(uint256 id) public view virtual override returns (string memory) {
    require(_exists(id), "ERC721Metadata: URI query for nonexistent token");
    return string(abi.encodePacked(baseURI, Strings.toString(id), ".json"));
  }

  //---------------------------------------------------------------
  //  CONSTRUCTOR
  //---------------------------------------------------------------

  constructor(string memory _baseURI) ERC721("FroyoKittens", "KITTENS") {
    baseURI = _baseURI;
    // Sunday, 10 April 2022 at 00:00 UTC
    mintStartTime = 1649563200;
  }

  function mint(uint256 amount) public payable {
    require(msg.value == (amount * NFT_PRICE), "WRONG_ETH_AMOUNT");
    require(owners.length + amount <= MAX_SUPPLY, "MAX_SUPPLY");
    require(block.timestamp >= mintStartTime, "NOT_LIVE");

    minters[msg.sender] += amount;
    require(minters[msg.sender] < 3, "ADDRESS_MAX_REACHED");
    for(uint256 i = 0; i < amount; i++) {
      _safeMint(msg.sender, owners.length);
    }
  }

  mapping (address => uint256) public minters;

  function burn(uint256 id) public {
    _burn(id);
  }

  /* name functions */
  mapping(uint256 => string) public tokenNames;

  function setName(uint256 id, string memory name) public {
    require(msg.sender == owners[id], "NOT_OWNER");
    tokenNames[id] = name;
  }

  //----------------------------------------------------------------
  //  WHITELISTS
  //----------------------------------------------------------------

  /// @dev - Merkle Tree root hash
  bytes32 public root;

  function setMerkleRoot(bytes32 merkleroot) public onlyOwner {
    root = merkleroot;
  }

  function premint(uint256 amount, bytes32[] calldata proof)
  external
  payable
  {
    address account = msg.sender;
    require(_verify(_leaf(account), proof), "INVALID_MERKLE_PROOF");
    require(msg.value == (amount * WHITELIST_PRICE), "WRONG_ETH_AMOUNT");
    require(owners.length + amount <= MAX_SUPPLY, "MAX_SUPPLY");

    minters[msg.sender] += amount;
    require(minters[account] < 3, "ADDRESS_MAX_REACHED");

    for(uint256 i = 0; i < amount; i++) {
      _safeMint(account, owners.length);
    }
  }

  function _leaf(address account)
  internal pure returns (bytes32)
  {
    return keccak256(abi.encodePacked(account));
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
  internal view returns (bool)
  {
    return MerkleProof.verify(proof, root, leaf);
  }

  //----------------------------------------------------------------
  //  ADMIN FUNCTIONS
  //----------------------------------------------------------------

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }
  function setMintStartTime(uint256 _startTime) public onlyOwner {
    mintStartTime = _startTime;
  }
  function setIsRevealed(bool _isRevealed) public onlyOwner {
    isRevealed = _isRevealed;
  }

  //---------------------------------------------------------------
  // WITHDRAWAL
  //---------------------------------------------------------------

  function withdraw(address to, uint256 amount) public onlyOwner {
    (bool success,) = payable(to).call{ value: amount }("");
    require(success, "WITHDRAWAL_FAILED");
  }
}
