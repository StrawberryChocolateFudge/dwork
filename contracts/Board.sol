// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/RoleLib.sol";
import "./libraries/BoardLib.sol";
import "./WorkSpaceFactory.sol";
import "./Dividends.sol";
import "hardhat/console.sol";

// The board is where the votings happen
// The hodlers of dwork token can vote to increate the fee the dividends contract collects
contract Board is AccessControl {
    using SafeERC20 for IERC20;
    using BoardLib for BoardState;

    event ProposalCreated(address creator, uint256 proposedFee);

    event Vote(address voter, uint256 to, bool ticket, uint256 weight);
    event VotingClosed(uint256 proposal, bool accepted);
    event ProposalFulfilled(uint256 proposal);

    BoardState private state;

    IERC20 private _token;

    WorkSpaceFactory private _factory;

    constructor(
        IERC20 token_,
        WorkSpaceFactory factory_,
        uint256 expiryTime,
        uint256 rateLimit,
        uint256 minimumShares
    ) {
        _token = token_;
        _factory = factory_;
        state.expiryTime = expiryTime;
        state.rateLimit = rateLimit;
        state.minimumShares = minimumShares;
    }

    function createProposal(uint16 setFeeTo) external {
        require(setFeeTo <= 1000, "521");
        require(hasEnoughShares(msg.sender), "Must have enough shares");
        state.createProposal(msg.sender, setFeeTo);
        emit ProposalCreated(msg.sender, setFeeTo);
    }

    // Anyone holding dworktokens can vote, the amount of tokens he holds is the vote weigth
    // only the proposal creator cannot vote
    function vote(uint256 to, bool ticket) external {
        state.vote(msg.sender, to, ticket, _token.balanceOf(msg.sender));
        emit Vote(msg.sender, to, ticket, _token.balanceOf(msg.sender));
    }

    // Anyone can close the voting, if it expired we got the results!
    function closeVoting(uint256 index) external {
        state.closeVoting(index);
        emit VotingClosed(
            index,
            state.votes[index][true] > state.votes[index][false]
        );
    }

    // These accepted proposals can be fulfilled by anyone
    function fulfillProposal(uint256 index) external {
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );
        _factory.setContractFee(state.proposals[index].setFeeTo);
        emit ProposalFulfilled(index);
    }

    function hasEnoughShares(address sender) internal view returns (bool) {
        return _token.balanceOf(sender) >= state.minimumShares;
    }

    function getLastProposalIndex() external view returns (uint256) {
        return state.lastIndex;
    }

    function getProposals(uint256 index)
        external
        view
        returns (Proposals memory)
    {
        return state.proposals[index];
    }

    function getVotes(uint256 index) external view returns (uint256, uint256) {
        return (state.votes[index][true], state.votes[index][false]);
    }

    function votedAlready(uint256 index, address _voter)
        external
        view
        returns (bool)
    {
        return state.votedAlready[index][_voter];
    }
}
