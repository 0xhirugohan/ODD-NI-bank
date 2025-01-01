// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import {OddNiBank} from "../src/OddNiBank.sol";
import {OddNiLoan} from "../src/OddNiLoan.sol";
import {Test} from "forge-std/Test.sol";

contract OddNiAuditTest is Test {
    // account
    address public deployer = makeAddr('deployer');
    address public tester = makeAddr('tester');

    OddNiBank public OBA;
    OddNiLoan public OBL;

    uint256 public constant DEAL_ETH_TO_DEPLOYER = 1000 ether;
    uint256 public constant ETH_TO_CREATE_CONTRACT = 200 ether;
    uint256 public constant DEAL_ETH_TO_TESTER = 100 ether;
    uint256 public constant BONUS_TO_PAY = 1 ether;
    uint256 public constant DEPOSIT_AMOUNT = 0.1 ether;

    function setUp() public {
    	vm.startPrank(deployer);
	vm.deal(deployer, DEAL_ETH_TO_DEPLOYER);
	OBA = new OddNiBank{value: ETH_TO_CREATE_CONTRACT}();
	OBL = new OddNiLoan{value: ETH_TO_CREATE_CONTRACT}(payable(address(OBA)));
	vm.stopPrank();
    }

    function testFirstTimeRegisterAsMember() public {
    	vm.startPrank(tester);
	vm.deal(tester, DEAL_ETH_TO_TESTER);
	uint256 contractInitialBalance = address(OBA).balance;
	OBA.registerAsMember();
	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	assertEq(contractInitialBalance, contractEndBalance);
	assertEq(testerEndBalance, DEAL_ETH_TO_TESTER);
	assert(OBA.getMemberStatus(tester));
	assertEq(OBA.getDepositedAmount(tester), 0);
    }

    function testRegisterAsMemberTwice() public {
    	testFirstTimeRegisterAsMember();
	vm.expectRevert(OddNiBank.AlreadyRegistered.selector);
	OBA.registerAsMember();
	assert(OBA.getMemberStatus(tester));
	assertEq(OBA.getDepositedAmount(tester), 0);
    }

    function testNonMemberClaimRegistrationBonus() public {
    	vm.startPrank(tester);
	vm.deal(tester, DEAL_ETH_TO_TESTER);
	uint256 contractInitialBalance = address(OBA).balance;
	vm.expectRevert(OddNiBank.NotMember.selector);
	OBA.claimRegistrationBonus();
	vm.stopPrank();
	assertEq(contractInitialBalance, address(OBA).balance);
	assert(!OBA.getMemberStatus(tester));
	assertEq(OBA.getDepositedAmount(tester), 0);
    }

    function testMemberClaimRegistrationBonus() public {
	testFirstTimeRegisterAsMember();

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDepositBalance = OBA.getDepositedAmount(tester);
	vm.startPrank(tester);
	OBA.claimRegistrationBonus();
	vm.stopPrank();
	assertEq(address(OBA).balance, contractInitialBalance - BONUS_TO_PAY);
	assertEq(address(tester).balance, testerInitialBalance + BONUS_TO_PAY);
	assertEq(OBA.getDepositedAmount(tester), testerInitialDepositBalance + BONUS_TO_PAY);
    }

    function testMemberClaimRegistrationBonusTwice() public {
    	testMemberClaimRegistrationBonus();

	uint256 contractInitialBalance = address(OBA).balance;
	vm.startPrank(tester);
	vm.expectRevert(OddNiBank.NotEligibleForBonus.selector);
	OBA.claimRegistrationBonus();
	vm.stopPrank();
	assertEq(contractInitialBalance, address(OBA).balance);
	assertEq(OBA.getDepositedAmount(tester), BONUS_TO_PAY);
    }

    function testClaimRegistrationBonusOnLowLiqudity() public {
	uint256 MIN_ETH_TO_CREATE_CONTRACT = 0.05 ether;

	vm.startPrank(deployer);
	vm.deal(deployer, DEAL_ETH_TO_DEPLOYER);
	OBA = new OddNiBank{value: MIN_ETH_TO_CREATE_CONTRACT}();
	vm.stopPrank();

 	vm.startPrank(tester);
	vm.deal(tester, DEAL_ETH_TO_TESTER);
	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	OBA.registerAsMember();

	vm.expectRevert("Failed to claim bonus!");
	OBA.claimRegistrationBonus();
	vm.stopPrank();

	assertEq(contractInitialBalance, address(OBA).balance);   	
	assertEq(testerInitialBalance, address(tester).balance);
    }

    function testNonMemberDepositAsset() public {
 	vm.startPrank(tester);
	vm.deal(tester, DEAL_ETH_TO_TESTER);
	
	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	vm.expectRevert(OddNiBank.NotMember.selector);
	OBA.depositAsset{value: DEPOSIT_AMOUNT}();
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance);
	assertEq(testerEndBalance, testerInitialBalance);
	assertEq(testerEndDeposit, testerInitialDeposit);
    }

    function testMemberDepositAsset() public {
    	testFirstTimeRegisterAsMember();

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	OBA.depositAsset{value: DEPOSIT_AMOUNT}();
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance + DEPOSIT_AMOUNT);
	assertEq(testerEndBalance, testerInitialBalance - DEPOSIT_AMOUNT);
	assertEq(testerEndDeposit, testerInitialDeposit + DEPOSIT_AMOUNT);
    }

    function testDepositAssetTwice() public {
	testFirstTimeRegisterAsMember();

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	OBA.depositAsset{value: DEPOSIT_AMOUNT}();
	OBA.depositAsset{value: DEPOSIT_AMOUNT}();
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	uint256 depositedAmount = 2 * DEPOSIT_AMOUNT;
	assertEq(contractEndBalance, contractInitialBalance + depositedAmount);
	assertEq(testerEndBalance, testerInitialBalance - depositedAmount);
	assertEq(testerEndDeposit, testerInitialDeposit + depositedAmount);
    }

    function testMemberDepositAndWithdraw() public {
 	testMemberDepositAsset();   

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	OBA.withdrawAsset(DEPOSIT_AMOUNT);
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance - DEPOSIT_AMOUNT);
	assertEq(testerEndBalance, testerInitialBalance + DEPOSIT_AMOUNT);
	assertEq(testerEndDeposit, testerInitialDeposit - DEPOSIT_AMOUNT);
    }

    function testMemberDepositAndWithdrawTwice() public {
 	testMemberDepositAsset();   

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	OBA.withdrawAsset(DEPOSIT_AMOUNT);
	vm.expectRevert();
	OBA.withdrawAsset(DEPOSIT_AMOUNT);
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance - DEPOSIT_AMOUNT);
	assertEq(testerEndBalance, testerInitialBalance + DEPOSIT_AMOUNT);
	assertEq(testerEndDeposit, testerInitialDeposit - DEPOSIT_AMOUNT);
    }

    function testMemberWithdrawGreaterThanDeposit() public {
 	testMemberDepositAsset();   

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	uint256 newDepositAmount = 2 * DEPOSIT_AMOUNT;

	vm.startPrank(tester);
	vm.expectRevert();
	OBA.withdrawAsset(newDepositAmount);
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance);
	assertEq(testerEndBalance, testerInitialBalance);
	assertEq(testerEndDeposit, testerInitialDeposit);
    }

    function testFlashloan() public {
 	testFirstTimeRegisterAsMember();   	

	uint256 contractInitialBalance = address(OBA).balance;
	uint256 testerInitialBalance = address(tester).balance;
	uint256 testerInitialDeposit = OBA.getDepositedAmount(tester);

	vm.startPrank(tester);
	OBL.loan(1 ether);
	vm.stopPrank();

	uint256 contractEndBalance = address(OBA).balance;
	uint256 testerEndBalance = address(tester).balance;
	uint256 testerEndDeposit = OBA.getDepositedAmount(tester);

	assertEq(contractEndBalance, contractInitialBalance);
	assertEq(testerEndBalance, testerInitialBalance);
	assertEq(testerEndDeposit, testerInitialDeposit);
    }
}
