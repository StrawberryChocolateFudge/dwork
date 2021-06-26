// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./DWorkToken.sol";

struct BoardState {
    uint256 lastIndex;
    //The index is incremented with each new proposal, it's used as a key for all three mapping
    mapping(uint256 => Proposals) proposals;
    mapping(uint256 => mapping(bool => uint256)) votes;
    //votes uses first a lastIndex key that maps to true or false
    //and the uint256 mapped to the bool is the WEIGHT of the votes, which will determine the results
    mapping(uint256 => mapping(address => bool)) votedAlready;
    //VotedAlready is used to check if an address voted already for a specific index
    //calling votedAlready[lastIndex][msg.sender] can return true if the sender already voted for the last proposal

    //Maintainers are active if their address maps to true
    mapping(address => bool) maintainers;
}

struct Proposals {
    address creator; //The address that created the proposal
    string metadataUrl;
    //This is the ipfs url containing the description of this proposal
    bytes32 identifier;
    //the identifier is calculated from the name of the function to call and the arguments for it
    //This way, the function call's validity can be validated when its called called.
    uint256 atBlock;
    //We store the block number of creation to know when it will expire
    Topic topic;
    Status status;
    MaintenanceTask maintenanceTask;
}

uint256 constant expiryTime = 100000; //Lets say 1 hundred thousand blocks are the expiry time of a proposal
uint256 constant minimumVote = 3; // The current minimum vote for a proposal to be accepted
uint256 constant enoughSharesDivideBy = 3000;

// DEVELOPMENT topics can be proposed by any share holder, the maintainers job is to fulfull the voted proposals.
// MAINTAINENCE topic is created by the maintainer and contains possible new library urls,
// disabling factory in case of emergency and ownership transfers. Maintainers don't need to have shares
// FEE_CHANGE topic proposals can be proposed by any share holder and revolve around a new fee for dividends
// ELECT_MAINTAINER topic proposals can be proposed by any share holder, to add a new maintainer
// REVOKE_MAINTAINER topic proposals can be proposed by and share holder, used to revoke maintainer rights
enum Topic {
    DEVELOPMENT,
    MAINTENANCE,
    FEE_CHANGE,
    ELECT_MAINTAINER,
    REVOKE_MAINTAINER
}

enum MaintenanceTask {
    NONE,
    SETDISABLED,
    SETWORKSPACELIBRARY,
    SETJOBLIBRARY,
    SETDIVIDENDSLIBRARY,
    WITHDRAWDIFFERENCE
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
        string calldata metadataUrl,
        bytes32 identifier,
        Topic topic,
        MaintenanceTask maintenanceTask
    ) external {
        self.lastIndex += 1;
        self.proposals[self.lastIndex] = Proposals({
            creator: creator,
            metadataUrl: metadataUrl,
            identifier: identifier,
            atBlock: block.number,
            topic: topic,
            status: Status.STARTED,
            maintenanceTask: maintenanceTask
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
            self.proposals[to].creator != sender,
            "The creator of the proposal cannot vote"
        );
        require(to > 0, "Cannot vote on zero index");
        require(to <= self.lastIndex, "Cannot vote on future proposals");
        require(
            self.proposals[to].atBlock + expiryTime > block.number,
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
    }

    function isMaintainer(BoardState storage self, address maintainer)
        external
        view
        returns (bool result)
    {
        return self.maintainers[maintainer];
    }
}

// THINGS TO VOTE ABOUT:

//Board:
//Elect maintainer
//revoke maintainer

//factory:
//setContractFee (uint16 _newFee)

//The bellow are all maintencance!

//setDisabled (bool _disabled)
//setWorkSpaceLibrary (address _address)
//setJobLibraryAddress (address _address)
//setDividendsLibraryAddress (address _address)

//dividends:
//all maintenance
//withdrawDifference
