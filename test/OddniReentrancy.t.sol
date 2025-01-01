// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {OddNiBad} from "../src/OddNiBad.sol";
import {OddNiBank} from "../src/OddNiBank.sol";
import {OddNiBenefit} from "../src/OddNiBenefit.sol";
import {Test} from "forge-std/Test.sol";

contract OddNiAuditTest is Test{
    address public deployer = makeAddr('deployer');
    address public tester = makeAddr('tester');
    address public innocent = makeAddr('innocent');
    address public attacker = makeAddr('attacker');

    OddNiBank public OBA;
    OddNiBad public OBB;
    OddNiBenefit public OBE;

    uint256 public constant MINIMUM_DEPOSIT = 5 ether;
    uint256 public constant MINIMUM_HOLD_DURATION = 30 days;
    uint256 public constant LOYALTY_REWARD = 0.1 ether;
    uint256 public constant BONUS_TO_PAY = 1 ether;

    uint256 public constant SMART_CONTRACT_DEPOSIT = 10 ether;
    uint256 public constant WALLET_DEPOSIT = 100 ether;
    uint256 public constant ATTACK_DEPOSIT = 1 ether;

    function setUp() public{
        vm.startPrank(deployer);
        vm.deal(deployer, WALLET_DEPOSIT);
        OBA = new OddNiBank{value: SMART_CONTRACT_DEPOSIT}();
	OBB = new OddNiBad{value: SMART_CONTRACT_DEPOSIT}(payable(address(OBA)));
        OBE = new OddNiBenefit{value: SMART_CONTRACT_DEPOSIT}(payable(address(OBA)));
        vm.stopPrank();
    }

    function testInnocentDeposit() public {
    	vm.startPrank(innocent);
	vm.deal(innocent, WALLET_DEPOSIT);
	uint initialOBABalance = address(OBA).balance;
	OBA.registerAsMember();
	OBA.depositAsset{value: SMART_CONTRACT_DEPOSIT}();
	uint OBABalance = address(OBA).balance;
	emit log_named_uint("OBA Balance: ", OBABalance);
	assertEq(OBABalance, initialOBABalance + SMART_CONTRACT_DEPOSIT);
    }

    function testBadContract() public {
    	testInnocentDeposit();
	vm.deal(attacker, WALLET_DEPOSIT);
	vm.startPrank(attacker);
	vm.expectRevert();
	OBB.attack{value: ATTACK_DEPOSIT}();
	uint OBABalanceAfterAttack = address(OBA).balance;
	emit log_named_uint("OBA Balance After Attack: ", OBABalanceAfterAttack);
	assert(OBABalanceAfterAttack != 0 ether);
    }
}
