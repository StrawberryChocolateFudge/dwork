// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;


struct DividendsState{
	uint256 totalBalance;
}

library DividendsLib{

	function setTotalBalance(DividendsState storage self,uint256 _balance) external{
		self.totalBalance += _balance;
	}
}