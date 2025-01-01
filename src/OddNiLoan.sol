// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { OddNiBank } from "./OddNiBank.sol";
import {console} from "lib/forge-std/src/console.sol";

contract OddNiLoan {
    OddNiBank public oddNiBank;
    uint256 private loanAmount;

    constructor (address payable _oddNiBankAddress) payable {
       oddNiBank = OddNiBank(_oddNiBankAddress); 
       oddNiBank.registerAsMember();
    }

    function loan(uint256 _amount) public {
	require(address(oddNiBank).balance >= _amount, "Insufficient funds");

	loanAmount = _amount;
	oddNiBank.flashloan(loanAmount);
    }

    fallback() external payable {
        require(msg.sender == address(oddNiBank), "Not OddNiBank Address");
	require(msg.value == loanAmount, "Not the loan amount");

	(bool returnedLoan, ) = address(oddNiBank).call{value: loanAmount}("");
	require(returnedLoan, "Return loan failed");
    }
}
