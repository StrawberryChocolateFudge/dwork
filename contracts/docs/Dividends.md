# Dividends

## Description

The Dividends contract allows DWORK token holders to claim fees collected from Jobs

## Events
`event Received(address sender, uint256 value);`
`event Claim(address sender, uint256 value, uint256 tokens);`
`event TokenWithdraw(address recepient, uint256 value, uint256 index);`
`event Reclaim(address claimer, uint256 value, uint256 tokens);`

## Public API

`receive() external payable`

Ether is sent to this contract by the jobs, this emits the Received event.
DO NOT SEND ETH to this contract manually. It will be claimed as dividends by others!

`claimDividends(uint256 amount) external nonReentrant`

A DWork token holder can claim dividends by locking ${amount} of DWORK tokens
The holder claims the ETH and locks the DWORK for a cycle, he may reclaim his tokens when the cycle ends
or he may lock them again.
The amount of locked tokens are stored indexed per lock.

`withdrawToken(uint256 index) external nonReentrant`
The deposited DWORK can be claimed,stored at index.

`reclaimDividends(uint256 index) external nonReentrant`
 The deposited DWORK can be reinvested for dividends again, the accounted for at index

`withdrawDifference(address to)
        external
        nonReentrant
        onlyOwner`

The owner can recover if somebody sent extra tokens by accident via a transfer function


## Public View Functions
`calculateDividends(uint256 amount)
        public
        view
        returns (uint256 payment)`

You can get the dividends calculated for an amount of DWORK

`getManagedTokens() external view returns (uint256)`

Returns the amount of tokens the contract manages

`getTotalBalance() external view returns (uint256)`

Returns the total balance deposited into the contract

`getCurrentBalance() external view returns (uint256)`

Returns the current balance of the tokens it uses to calculate the dividend payouts

`getCurrentIndex() external view returns (uint256)`

Returns the current index the sender is at, all the token deposits are accounted for at different indexes

`getHistory(uint256 index) external view returns (Balance memory)`

Returns the balance object at index, the deposited tokens are accounted for in these objects