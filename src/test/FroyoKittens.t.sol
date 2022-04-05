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

  uint256 public constant MINT_PRICE = 0.1 ether;
  FroyoKittens froyoKittens;
  constructor(FroyoKittens _froyoKittens) {
    froyoKittens = _froyoKittens;
  }

  function mint(uint256 amount) public {
    uint256 value = MINT_PRICE * amount;
    _mint(amount, value);
  }
  function badMintPrice(uint256 amount) public {
    uint256 value = 1 * amount;
    _mint(amount, value);
  }
  function premint(uint256 amount, bytes32[] calldata proof) public {
    froyoKittens.premint(amount, proof);
  }
  function _mint(uint256 amount, uint256 value) internal {
    froyoKittens.mint{value: value}(amount);
  }
  function transfer(address to, uint256 tokenId) public {
    transferFor(address(this), to, tokenId);
  }
  function transferFor(address from, address to, uint256 tokenId) public {
    froyoKittens.transferFrom(from, to, tokenId);
  }
  function approve(address to, uint256 tokenId) public {
    froyoKittens.approve(to, tokenId);
  }
  function approveAll(address to, bool isApproved) public {
    froyoKittens.setApprovalForAll(to, isApproved);
  }
  function burn(uint256 tokenId) public {
    froyoKittens.burn(tokenId);
  }
  function setName(uint256 id, string memory name) public {
    froyoKittens.setName(id, name);
  }

  function setBaseURI(string memory uri) public {
    froyoKittens.setBaseURI(uri);
  }
  function setMintStartTime(uint256 _startTime) public {
    froyoKittens.setMintStartTime(_startTime);
  }
  function setIsRevealed(bool isRevealed) public {
    froyoKittens.setIsRevealed(isRevealed);
  }



  function withdraw() public {
    // froyoKittens.withdraw();
  }

  function receivePayment() public payable {}

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract FroyoKittensTest is DSTest {
  FroyoKittens froyoKittens;
  User userA;
  User userB;
  User userC;
  User userNoFunds;
  Hevm hevm;

  address constant user = address(0xFdeAA01bbac12C37d2F90Fe8B988b76719089E47);
  string constant BASE_URI = "ipfs://QmTK84gc6eCekRagAFduG7S1Ce8HaWs83tFJPQaD728brY";

  function setUp() public {
    froyoKittens = new FroyoKittens(BASE_URI);
    userA = new User(froyoKittens);
    userB = new User(froyoKittens);
    userC = new User(froyoKittens);
    userNoFunds = new User(froyoKittens);
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    hevm.warp(1649563200);
    uint256 eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
    userC.deposit{value: eth}();
  }

  function testMintOne() public {
    userA.mint(1);
    uint256 balance = froyoKittens.balanceOf(address(userA));
    assertEq(1, balance);
  }
  function testMintTwoAtOnce() public {
    userA.mint(2);
    uint256 balance = froyoKittens.balanceOf(address(userA));
    assertEq(2, balance);
  }
  function testMintTwoSequentially() public {
    userA.mint(1);
    uint256 balance1 = froyoKittens.balanceOf(address(userA));
    assertEq(1, balance1);
    userA.mint(1);
    uint256 balance2 = froyoKittens.balanceOf(address(userA));
    assertEq(2, balance2);
  }
  function testFailMintThree() public {
    userA.mint(3);
  }
  function testBurnAdjustsUserBalance() public {
    userA.mint(2);

    uint256 balance1 = froyoKittens.balanceOf(address(userA));
    assertEq(balance1, 2);
    userA.burn(0);

    uint256 balance2 = froyoKittens.balanceOf(address(userA));
    assertEq(balance2, 1);
  }

  function testBurnAdjustsTotalSupply() public {
    userA.mint(2);
    userB.mint(2);
    userC.mint(2);
    uint256 postMintSupply = froyoKittens.totalSupply();
    assertEq(postMintSupply, 6);

    userA.burn(0);
    userB.burn(2);

    uint256 postBurnSupply = froyoKittens.totalSupply();
    assertEq(postBurnSupply, 4);
  }

  function testBurnedTokensAreZeroWithNoBurns() public {
    assertEq(froyoKittens.burnedTokens(), 0);
    userA.mint(2);
    assertEq(froyoKittens.burnedTokens(), 0);
    userA.burn(1);
    assertEq(froyoKittens.burnedTokens(), 1);
    userA.burn(0);
    assertEq(froyoKittens.burnedTokens(), 2);
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
    userA.mint(2);
    userB.mint(1);
    assertEq(froyoKittens.balanceOf(address(userA)), 2);
    assertEq(froyoKittens.owners(0), address(userA));
    assertEq(froyoKittens.owners(1), address(userA));
    assertEq(froyoKittens.owners(2), address(userB));

    userA.burn(1);

    assertEq(froyoKittens.balanceOf(address(userA)), 1);
    assertEq(froyoKittens.owners(0), address(userA));
    assertEq(froyoKittens.owners(1), address(0));
    assertEq(froyoKittens.owners(2), address(userB));
  }
  function testTokenOfOwnerByIndex() public {
    userA.mint(2);
    userB.mint(1);

    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userA), 1), 1);
    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userB), 0), 2);
  }
  function testBurnAndTokenOfOwnerByIndexPreservesOwnership() public {
    userA.mint(2);
    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userA), 0), 0);
    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userA), 1), 1);
    assertEq(froyoKittens.balanceOf(address(userA)), 2);

    userA.burn(1);
    assertEq(froyoKittens.balanceOf(address(userA)), 1);
    assertEq(froyoKittens.tokenOfOwnerByIndex(address(userA), 0), 0);
  }

  function testFailTokenOfOwnerByIndex() public {
    userA.mint(2);
    froyoKittens.tokenOfOwnerByIndex(address(userA), 2);
  }

  function testFailMintWrongAmount() public {
    userA.badMintPrice(1);
  }
  function testFailMintNotEnoughFunds() public {
    userNoFunds.mint(1);
  }

  function testTransferToUserB() public {
    userA.mint(1);
    assertEq(froyoKittens.balanceOf(address(userA)), 1);
    assertEq(froyoKittens.balanceOf(address(userB)), 0);
    userA.transfer(address(userB), 0);
    assertEq(froyoKittens.balanceOf(address(userA)), 0);
    assertEq(froyoKittens.balanceOf(address(userB)), 1);
  }

  function testFailTransferWithoutApproval() public {
    userA.mint(1);
    userB.transferFor(address(userA), address(userC), 0);
  }

  function testTransferForWithApprove1() public {
    userA.mint(1);
    userA.approve(address(userB), 0);
    userB.transferFor(address(userA), address(userC), 0);
    assertEq(froyoKittens.balanceOf(address(userA)), 0);
    assertEq(froyoKittens.balanceOf(address(userC)), 1);
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
    userA.mint(2);
    uint256 tokenIndex = froyoKittens.tokenByIndex(1);
    assertEq(tokenIndex, 1);
  }

  function testSetName() public {
    string memory expected = "MY NAME 1";
    userA.mint(1);
    userA.setName(0, expected);
    string memory actual = froyoKittens.tokenNames(0);
    assertEq(actual, expected);
  }
  function testFailSetNameForUnowned() public {
    userA.mint(1);
    userB.setName(0, "");
  }


  function testBaseUriSetAtDeploy() public {
    string memory contractUri = froyoKittens.baseURI();
    assertEq(contractUri, BASE_URI);
  }
  function testTokenUriReturnsValueAfterReveal() public {
    userA.mint(2);

    froyoKittens.setBaseURI("ipfs://BASE/");
    froyoKittens.setIsRevealed(true);
    string memory tokenURI = froyoKittens.tokenURI(1);
    assertEq(tokenURI, "ipfs://BASE/1.json");
  }
  function testOwnerCanSetBaseUri() public {
    string memory uri = "ipfs://BASE/";
    froyoKittens.setBaseURI(uri);

    string memory contractUri = froyoKittens.baseURI();
    assertEq(contractUri, uri);
  }
  function testFailSetBaseUri_NotOwner() public {
    userA.setBaseURI("ipfs://FAIL/");
  }
  function testOwnerCanSetIsMintStartTime() public {
    froyoKittens.setMintStartTime(1);
    uint256 startBlock = froyoKittens.mintStartTime();
    assertTrue(startBlock == 1);
  }
  function testFailSetIsMintStartTime_NotOwner() public {
    userA.setMintStartTime(1);
  }
  function testOwnerCanSetIsRevealed() public {
    froyoKittens.setIsRevealed(true);
    bool isRevealed = froyoKittens.isRevealed();
    assertTrue(isRevealed);
  }
  function testFailSetIsRevealed_NotOwner() public {
    userA.setIsRevealed(true);
  }
  function testFailMint_GivenStartTimeIsInFuture() public {
    // 10 Apr 2022 at midnight + 1 tick
    froyoKittens.setMintStartTime(1649563201);
    userA.mint(1);
  }
  function testFailMint_GivenHEVMIsWarpedToThePast() public {
    hevm.warp(160000000);
    userA.mint(1);
  }
}

