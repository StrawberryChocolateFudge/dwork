// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DWorkToken.sol";
//The board is where the votings happen
//There is a maintainer role used here that can create proposals for changing libraryUrls and disable the contract
//The rest of the proposals have to be created by a user holding at least 10% of the total supply 

//There can be proposals to add maintainers, the board is the "owner" of the factory.
//It's mostly gonna be used to vote on the dividends fee.
//for upgrade path, the board can vote to create new board contract by transfering ownership 

contract Board is AccessControl{

}