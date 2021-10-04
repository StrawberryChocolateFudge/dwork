# DworkCrowdSale

## Description

The crowdsale does what the name implies and sells DWork tokens

## Events

`event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );`

`event TokensWithdrawn(address to, uint256 value);`

## Public API

`buyTokens(address beneficiary) public payable nonReentrant`

`receive() external payable`

You can send ETH to this address. It will run buyTokens() from the recieve function. The tokens will be payed to the beneficiary address.
If you choose to just transfer, the receive function triggers and passes in the beneficiary as msg.sender.


`adminTransfer(uint256 value, address to)
        external
        nonReentrant
        onlyRole(RoleLib.ADMIN_ROLE)`

Called by the admin role, he may transfer the tokens out if they are not sold.

## Public View functions

`token() public view returns (IERC20)`

Returns the token being sold

`wallet() public view returns (address payable)`

Returns the wallet address that will receive the eth

`rate() public view returns (uint256)`

Returns the rate the contract sells the tokens for

` weiRaised() public view returns (uint256)`

Returns the amount of wei raised by the contract


