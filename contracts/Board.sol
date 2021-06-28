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
    //I will have a contract level lock for some funtions
    //using integers cuz I read they are more cheap than bools
    uint256 lock;

    constructor(
        IERC20 token_,
        WorkSpaceFactory factory_,
        uint256 expiryTime,
        uint256 rateLimit
    ) {
        _token = token_;
        _factory = factory_;
        state.expiryTime = expiryTime;
        state.rateLimit = rateLimit;
    }

    //TODO: refactor to library more implementations!
    //TODO: Maybe I could scrape the idea of maintainers , if the project goes well, maintenance should not be needed
    function createProposal(uint16 setFeeTo) external {
        require(setFeeTo <= 1000, "521");

        require(hasEnoughShares(msg.sender), "Must have enough shares");

        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        state.createProposal(msg.sender, setFeeTo);
        emit ProposalCreated(msg.sender, setFeeTo);
        lock = 0;
    }

    // Anyone holding dworktokens can vote, the amount of tokens he holds is the vote weigth
    // only the proposal creator cannot vote
    function vote(uint256 to, bool ticket) external {
        state.vote(msg.sender, to, ticket, _token.balanceOf(msg.sender));
        emit Vote(msg.sender, to, ticket, _token.balanceOf(msg.sender));
    }

    // Anyone can close the voting, if it expired we got the results!
    function closeVoting(uint256 index) external {
        require(index > 0, "Cannot vote on zero index");
        require(index <= state.lastIndex, "Cannot vote on future proposals");
        require(
            state.proposals[index].initialized,
            "The proposal is not initialized"
        );
        require(
            state.proposals[index].status == Status.STARTED,
            "The proposal already closed"
        );
        require(
            state.proposals[index].atBlock + state.expiryTime < block.number,
            "The proposal didnt expire,yet"
        );

        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        //Count the votes weight and set the results
        if (state.votes[index][true] > state.votes[index][false]) {
            state.proposals[index].status = Status.ACCEPTED;
        } else {
            state.proposals[index].status = Status.REJECTED;
        }

        // need a minimum of 3 votes,
        if (state.proposals[index].voteCount < 3) {
            state.proposals[index].status = Status.REJECTED;
        }
        emit VotingClosed(
            index,
            state.votes[index][true] > state.votes[index][false]
        );
        lock = 0;
    }

    // These accepted proposals can be fulfilled by anyone
    function fulfillProposal(uint256 index) external {
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );
        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        _factory.setContractFee(state.proposals[index].setFeeTo);
        emit ProposalFulfilled(index);
        lock = 0;
    }

    function hasEnoughShares(address sender) internal view returns (bool) {
        return
            _token.balanceOf(sender) >=
            _token.totalSupply() / enoughSharesDivideBy;
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
