// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./DWorkToken.sol";
// The board is where the votings happen
// There is a maintainer role used here that can create proposals for changing libraryUrls and disable the contract
// The rest of the proposals have to be created by a user holding at least 10% of the total supply 

// There can be proposals to add maintainers, the board is the "owner" of the factory and the dividends contract!
// It's mostly gonna be used to vote on the dividends fee.
// for upgrade path, the board can vote to create new board contract by then 
// transfer ownership of the factory and the dividends contracts

// DEVELOPMENT topics can be proposed by any share holder, the maintainers job is to fulfull the voted proposals.
// MAINTAINENCE topic is created by the maintainer and contains possible new library urls,
// disabling factory in case of emergency and ownership transfers. Maintainers don't need to have shares
// FEE_CHANGE topic proposals can be proposed by any share holder and revolve around a new fee for dividendsa
// ELECT_MAINTAINER topic proposals can be proposed by any share holder, to add
// REVOKE_MAINTAINER topic proposals can be proposed by and share holder, used to revoke maintainer rights
enum Topic{DEVELOPMENT,MAINTAINENCE,FEE_CHANGE,ELECT_MAINTAINER}



contract Board is AccessControl{

}