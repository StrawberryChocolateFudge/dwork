// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "../DWorkToken.sol";
struct BoardState {
    // the minimum shares for porposal creation
    uint256 minimumShares;
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
            "571"
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
        verifyVote(self, to, sender);
        self.votedAlready[to][sender] = true;
        self.votes[to][ticket] += weight;
        self.proposals[to].voteCount += 1;
    }

    function verifyVote(
        BoardState storage self,
        uint256 to,
        address sender
    ) internal view {
        require(self.proposals[to].initialized, "573");
        require(self.proposals[to].creator != sender, "574");
        require(self.proposals[to].status == Status.STARTED, "578");
        require(
            self.proposals[to].atBlock + self.expiryTime > block.number,
            "577"
        );

        require(self.votedAlready[to][sender] == false, "579");
    }

    function closeVoting(BoardState storage self, uint256 index) external {
        require(index > 0, "580");
        require(index <= self.lastIndex, "581");
        require(self.proposals[index].initialized, "582");
        require(self.proposals[index].status == Status.STARTED, "583");
        require(
            self.proposals[index].atBlock + self.expiryTime < block.number,
            "584"
        );

        //Count the votes weight and set the results
        if (self.votes[index][true] > self.votes[index][false]) {
            self.proposals[index].status = Status.ACCEPTED;
        } else {
            self.proposals[index].status = Status.REJECTED;
        }

        // need a minimum of 3 votes,
        if (self.proposals[index].voteCount < 3) {
            self.proposals[index].status = Status.REJECTED;
        }
    }
}
