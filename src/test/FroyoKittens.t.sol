// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { DSTest } from "ds-test/test.sol";

import "../FroyoKittens.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

abstract contract Hevm {
  function warp(uint256) public virtual;
  function roll(uint256) public virtual;
}

contract User is ERC721Holder {

  uint256 public constant MINT_PRICE = 0.001 ether;
  FroyoKittens demonParty;
  constructor(FroyoKittens _demonParty) {
    demonParty = _demonParty;
  }

  function mint(uint256 amount) public {
    uint256 value = MINT_PRICE * amount;
    _mint(amount, value);
  }
  function badMintPrice(uint256 amount) public {
    uint256 value = 1 * amount;
    _mint(amount, value);
  }
  function giftMint(address to, uint256 amount) public {
    demonParty.gift(to, amount);
  }
  function premint(address to, uint256 amount, bytes32[] calldata proof) public {
    demonParty.premint(to, amount, proof);
  }
  function _mint(uint256 amount, uint256 value) internal {
    demonParty.mint{value: value}(amount);
  }
  function transfer(address to, uint256 tokenId) public {
    transferFor(address(this), to, tokenId);
  }
  function transferFor(address from, address to, uint256 tokenId) public {
    demonParty.transferFrom(from, to, tokenId);
  }
  function approve(address to, uint256 tokenId) public {
    demonParty.approve(to, tokenId);
  }
  function approveAll(address to, bool isApproved) public {
    demonParty.setApprovalForAll(to, isApproved);
  }
  function burn(uint256 tokenId) public {
    demonParty.burn(tokenId);
  }
  function setName(uint256 id, string memory name) public {
    demonParty.setName(id, name);
  }

  function setBaseURI(string memory uri) public {
    demonParty.setBaseURI(uri);
  }
  function setIsMintLive(bool isLive) public {
    demonParty.setIsMintLive(isLive);
  }
  function setIsRevealed(bool isRevealed) public {
    demonParty.setIsRevealed(isRevealed);
  }



  function withdraw() public {
    // demonParty.withdraw();
  }

  function receivePayment() public payable {}

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract FroyoKittensTest is DSTest {
  FroyoKittens demonParty;
  User userA;
  User userB;
  User userC;
  User userNoFunds;
  Hevm hevm;

  address constant user = address(0xFdeAA01bbac12C37d2F90Fe8B988b76719089E47);
  string constant BASE_URI = "ipfs://QmTK84gc6eCekRagAFduG7S1Ce8HaWs83tFJPQaD728brY";

  function setUp() public {
    demonParty = new FroyoKittens(BASE_URI);
    demonParty.setIsMintLive(true);
    userA = new User(demonParty);
    userB = new User(demonParty);
    userC = new User(demonParty);
    userNoFunds = new User(demonParty);
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    hevm.roll(1000001);
    uint256 eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
    userC.deposit{value: eth}();
  }

  function testMintOne() public {
    userA.mint(1);
    uint256 balance = demonParty.balanceOf(address(userA));
    assertEq(1, balance);
  }
  function testMintThreeAtOnce() public {
    userA.mint(1);
    uint256 balance1 = demonParty.balanceOf(address(userA));
    assertEq(1, balance1);
    userA.mint(1);
    uint256 balance2 = demonParty.balanceOf(address(userA));
    assertEq(2, balance2);
    userA.mint(1);
    uint256 balance3 = demonParty.balanceOf(address(userA));
    assertEq(3, balance3);
  }
  function testMintThreeSequentially() public {
    userA.mint(3);
    uint256 balance = demonParty.balanceOf(address(userA));
    assertEq(3, balance);
  }
  function testFailMintFour() public {
    userA.mint(4);
  }
  function testBurnAdjustsUserBalance() public {
    userA.mint(3);

    uint256 balance1 = demonParty.balanceOf(address(userA));
    assertEq(balance1, 3);
    userA.burn(0);

    uint256 balance2 = demonParty.balanceOf(address(userA));
    assertEq(balance2, 2);
  }

  function testBurnAdjustsTotalSupply() public {
    demonParty.gift(address(userA), 10);
    demonParty.gift(address(userB), 10);
    demonParty.gift(address(userC), 10);
    uint256 postMintSupply = demonParty.totalSupply();
    assertEq(postMintSupply, 30);

    userA.burn(0);
    userA.burn(1);
    userA.burn(2);
    userA.burn(3);
    userA.burn(4);

    uint256 postBurnSupply = demonParty.totalSupply();
    assertEq(postBurnSupply, 25);
  }

  function testBurnedTokensAreZeroWithNoBurns() public {
    assertEq(demonParty.burnedTokens(), 0);
    userA.mint(3);
    assertEq(demonParty.burnedTokens(), 0);
    userA.burn(2);
    assertEq(demonParty.burnedTokens(), 1);
    userA.burn(0);
    assertEq(demonParty.burnedTokens(), 2);
  }

  function testFailBurnWithZeroOwned() public {
    userA.burn(0);
  }
  function testFailBurnWithUnownedToken() public {
    userA.mint(1);
    userB.mint(1);
    userC.mint(1);
    userA.burn(2);
  }
  function testBurnPreservesOwnership() public {
    userA.mint(3);
    userB.mint(1);
    assertEq(demonParty.balanceOf(address(userA)), 3);
    assertEq(demonParty.owners(0), address(userA));
    assertEq(demonParty.owners(1), address(userA));
    assertEq(demonParty.owners(2), address(userA));
    assertEq(demonParty.owners(3), address(userB));

    userA.burn(1);

    assertEq(demonParty.balanceOf(address(userA)), 2);
    assertEq(demonParty.owners(0), address(userA));
    assertEq(demonParty.owners(1), address(0));
    assertEq(demonParty.owners(2), address(userA));
    assertEq(demonParty.owners(3), address(userB));
  }
  function testTokenOfOwnerByIndex() public {
    userA.mint(3);
    userB.mint(1);

    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 1), 1);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 2), 2);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userB), 0), 3);
  }
  function testBurnAndTokenOfOwnerByIndexPreservesOwnership() public {
    userA.mint(3);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 1), 1);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 2), 2);
    assertEq(demonParty.balanceOf(address(userA)), 3);

    userA.burn(1);
    assertEq(demonParty.balanceOf(address(userA)), 2);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(demonParty.tokenOfOwnerByIndex(address(userA), 1), 2);
  }

  function testFailTokenOfOwnerByIndex() public {
    userA.mint(3);
    demonParty.tokenOfOwnerByIndex(address(userA), 3);
  }

  function testFailMintWrongAmount() public {
    userA.badMintPrice(1);
  }
  function testFailMintNotEnoughFunds() public {
    userNoFunds.mint(1);
  }

  function testTransferToUserB() public {
    userA.mint(1);
    assertEq(demonParty.balanceOf(address(userA)), 1);
    assertEq(demonParty.balanceOf(address(userB)), 0);
    userA.transfer(address(userB), 0);
    assertEq(demonParty.balanceOf(address(userA)), 0);
    assertEq(demonParty.balanceOf(address(userB)), 1);
  }

  function testFailTransferWithoutApproval() public {
    userA.mint(1);
    userB.transferFor(address(userA), address(userC), 0);
  }

  function testTransferForWithApprove1() public {
    userA.mint(1);
    userA.approve(address(userB), 0);
    userB.transferFor(address(userA), address(userC), 0);
    assertEq(demonParty.balanceOf(address(userA)), 0);
    assertEq(demonParty.balanceOf(address(userC)), 1);
  }
  function testFailApproveForUnownedToken() public {
    userA.mint(1);
    userB.approve(address(userA), 0);
  }
  function testFailApproveForNonexistentToken() public {
    userA.mint(1);
    userA.approve(address(userA), 1);
  }
  function testTransferForWithApproveAll() public {
    userA.mint(1);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 0);
  }
  function testFailTransferForWithRevokedApproval() public {
    userA.mint(3);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 0);
    userA.approveAll(address(userB), false);
    userB.transferFor(address(userA), address(userC), 1);
  }
  function testFailTransferForUnownedTokens() public {
    userA.mint(3);
    userC.mint(3);
    userA.approveAll(address(userB), true);
    userB.transferFor(address(userA), address(userC), 4);
  }

  function testTokenByIndex() public {
    userA.mint(3);
    uint256 tokenIndex = demonParty.tokenByIndex(2);
    assertEq(tokenIndex, 2);
  }

  function testSetName() public {
    string memory expected = "MY NAME 1";
    userA.mint(1);
    userA.setName(0, expected);
    string memory actual = demonParty.tokenNames(0);
    assertEq(actual, expected);
  }
  function testFailSetNameForUnowned() public {
    userA.mint(1);
    userB.setName(0, "");
  }

  function testGiftWorks_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 1);
    uint256 balance = demonParty.balanceOf(address(userC));
    assertEq(balance, 1);
  }
  function testGift3Works_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 3);
    uint256 balance = demonParty.balanceOf(address(userC));
    assertEq(balance, 3);
  }
  function testGift10_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 10);
    uint256 balance = demonParty.balanceOf(address(userC));
    assertEq(balance, 10);
  }
  function testGift3Then7Works_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 3);
    uint256 balance = demonParty.balanceOf(address(userC));
    assertEq(balance, 3);

    demonParty.gift(address(userC), 7);
    uint256 balance2 = demonParty.balanceOf(address(userC));
    assertEq(balance2, 10);
  }
  function testFailGift11_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 11);
  }
  function testFailGift12_NotLive() public {
    demonParty.setIsMintLive(false);
    demonParty.gift(address(userC), 12);
  }
  function testFailGift_NonOwner() public {
    demonParty.setIsMintLive(false);
    userB.giftMint(address(userA), 1);
  }
  function testFailPublicMintAfterMaxGifted() public {
    demonParty.gift(address(userC), 10);
    userC.mint(1);
  }
  function testFailPublicMintAfter5Gifted() public {
    demonParty.gift(address(userC), 10);
    userC.mint(1);
  }
  function testPublicMintOneAfter2Gifted() public {
    demonParty.gift(address(userC), 2);
    userC.mint(1);
    uint256 balance = demonParty.balanceOf(address(userC));
    assertEq(balance, 3);
  }
  function testFailPublicMintTooManyAfter2Gifted() public {
    demonParty.gift(address(userC), 2);
    userC.mint(2);
  }

  function testBaseUriSetAtDeploy() public {
    string memory contractUri = demonParty.baseURI();
    assertEq(contractUri, BASE_URI);
  }
  function testTokenUriReturnsValueAfterReveal() public {
    userA.mint(3);

    demonParty.setBaseURI("ipfs://BASE/");
    demonParty.setIsRevealed(true);
    string memory tokenURI = demonParty.tokenURI(2);
    assertEq(tokenURI, "ipfs://BASE/2.json");
  }
  function testOwnerCanSetBaseUri() public {
    string memory uri = "ipfs://BASE/";
    demonParty.setBaseURI(uri);

    string memory contractUri = demonParty.baseURI();
    assertEq(contractUri, uri);
  }
  function testFailSetBaseUri_NotOwner() public {
    userA.setBaseURI("ipfs://FAIL/");
  }
  function testOwnerCanSetIsMintLive() public {
    demonParty.setIsMintLive(true);
    bool isLive = demonParty.isMintLive();
    assertTrue(isLive);
  }
  function testFailSetIsMintLive_NotOwner() public {
    userA.setIsMintLive(true);
  }
  function testOwnerCanSetIsRevealed() public {
    demonParty.setIsRevealed(true);
    bool isRevealed = demonParty.isRevealed();
    assertTrue(isRevealed);
  }
  function testFailSetIsRevealed_NotOwner() public {
    userA.setIsRevealed(true);
  }
}

