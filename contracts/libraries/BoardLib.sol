// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "../DWorkToken.sol";

struct BoardState {
    //The expiry time of a proposal in blocks
    uint256 expiryTime;
    //A lot of proposals must not be created by the same address, I have a rate limit
    uint256 rateLimit;
    uint256 lastIndex;
    //The index is incremented with each new proposal, it's used as a key for all three mapping
    mapping(uint256 => Proposals) proposals;
    mapping(uint256 => mapping(bool => uint256)) votes;
    //votes uses first a lastIndex key that maps to true or false
    //and the uint256 mapped to the bool is the WEIGHT of the votes, which will determine the results
    mapping(uint256 => mapping(address => bool)) votedAlready;
    //VotedAlready is used to check if an address voted already for a specific index
    //calling votedAlready[lastIndex][msg.sender] can return true if the sender already voted for the last proposal

    //A mapping to store the last block when a proposal was made by an address
    //There is a rate limit for how often someone can create proposals
    mapping(address => uint256) propositionDate;
}

struct Proposals {
    bool initialized;
    uint256 voteCount;
    address creator; //The address that created the proposal
    uint256 atBlock;
    //We store the block number of creation to know when it will expire
    Status status;
    uint16 setFeeTo;
}

uint256 constant enoughSharesDivideBy = 3000;

// Status is used to determine if voting on the proposal has started and the result of the vote
// A proposal has "started" as a default and based on the valuation, accepted or rejected.
// Fulfilled is set if the function required to be called as a result is called
enum Status {
    STARTED,
    ACCEPTED,
    REJECTED,
    FULFILLED
}

library BoardLib {
    function createProposal(
        BoardState storage self,
        address creator,
        uint16 setFeeTo
    ) external {
        require(
            self.propositionDate[creator] + self.rateLimit < block.number,
            "You have to wait to make more propositions"
        );

        self.propositionDate[creator] = block.number;
        self.lastIndex += 1;
        self.proposals[self.lastIndex] = Proposals({
            initialized: true,
            creator: creator,
            voteCount: 0,
            atBlock: block.number,
            status: Status.STARTED,
            setFeeTo: setFeeTo
        });
    }

    function vote(
        BoardState storage self,
        address sender,
        uint256 to,
        bool ticket,
        uint256 weight
    ) external {
        require(
            self.proposals[to].initialized,
            "The proposal is not initialized"
        );
        require(
            self.proposals[to].creator != sender,
            "The creator of the proposal cannot vote"
        );
        require(to > 0, "Cannot vote on zero index");
        require(to <= self.lastIndex, "Cannot vote on future proposals");
        require(
            self.proposals[to].atBlock + self.expiryTime > block.number,
            "The proposal expired"
        );

        require(
            self.proposals[to].status == Status.STARTED,
            "Cant vote on closed proposals"
        );
        require(
            self.votedAlready[to][sender] == false,
            "The sender voted already"
        );
        self.votes[to][ticket] += weight;
        self.proposals[to].voteCount += 1;
    }
}
