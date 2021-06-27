// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/RoleLib.sol";
import "./libraries/BoardLib.sol";
import "./WorkSpaceFactory.sol";
import "./Dividends.sol";
import "./interfaces/BoardCallableFactory.sol";
import "./interfaces/BoardCallableDividends.sol";
import "hardhat/console.sol";

// The board is where the votings happen
// There is a maintainer role used here that can create proposals for changing libraryUrls and disable the contract
// The rest of the proposals have to be created by a user holding at least 1% of the total supply

// There can be proposals to add maintainers, the board is the "owner" of the factory and the dividends contract!
// It's mostly gonna be used to vote on the dividends fee.
// for upgrade path, the board can vote to create new board contract by then
// transfer ownership of the factory and the dividends contracts

contract Board is AccessControl {
    using SafeERC20 for IERC20;
    using BoardLib for BoardState;

    event ProposalCreated(
        address creator,
        string metadataUrl,
        Topic topic,
        MaintenanceTask maintenanceTask
    );

    event Vote(address voter, uint256 to, bool ticket, uint256 weight);
    event VotingClosed(uint256 proposal, bool accepted);
    event ProposalFulfilled(
        uint256 proposal,
        Topic topic,
        MaintenanceTask task
    );

    //TODO: ADD BANNING FUNCTIONALITY.
    //BAN FROM VOTING
    //Maintainer shouild be able to disable proposals!

    BoardState private state;

    IERC20 private _token;
    BoardCallableFactory private _factory;
    BoardCallableDividends private _dividends;
    //I will have a contract level lock for some funtions
    //using integers cuz I read they are more cheap than bools
    uint256 lock;

    constructor(
        IERC20 token_,
        WorkSpaceFactory factory_,
        address firstMaintainer,
        uint256 expiryTime,
        uint256 rateLimit
    ) {
        _token = token_;
        _factory = factory_;
        state.maintainers[firstMaintainer] = true;
        state.expiryTime = expiryTime;
        state.rateLimit = rateLimit;
    }

    //TODO: refactor to library more implementations!
    function createProposal(
        string calldata metadataUrl,
        Topic topic,
        MaintenanceTask maintenanceTask,
        uint16 setFeeTo,
        address setMaintainerTo,
        bool setDisabledTo,
        address setAddressTo
    ) external {
        if (topic == Topic.MAINTENANCE) {
            require(
                state.isMaintainer(msg.sender),
                "Must have maintainer role"
            );
        } else {
            require(hasEnoughShares(msg.sender), "Must have enough shares");
        }
        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        state.createProposal(
            msg.sender,
            metadataUrl,
            topic,
            maintenanceTask,
            setFeeTo,
            setMaintainerTo,
            setDisabledTo,
            setAddressTo
        );
        emit ProposalCreated(msg.sender, metadataUrl, topic, maintenanceTask);
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
        if (state.proposals[index].topic != Topic.MAINTENANCE) {
            // non-maintenance topics need a minimum of 3 votes,
            if (state.proposals[index].voteCount <= 3) {
                state.proposals[index].status = Status.REJECTED;
            }
        }

        emit VotingClosed(
            index,
            state.votes[index][true] > state.votes[index][false]
        );
        lock = 0;
    }

    // These accepted proposals can be fulfilled by anyone
    //  FEE_CHANGE
    function fulfillFeeChangeProposal(uint256 index) external {
        require(
            state.proposals[index].topic == Topic.FEE_CHANGE,
            "Proposal must be Fee change"
        );
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );
        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        _factory.setContractFee(state.proposals[index].setFeeTo);
        emit ProposalFulfilled(index, Topic.FEE_CHANGE, MaintenanceTask.NONE);
        lock = 0;
    }

    // ELECT_MAINTAINER
    // REVOKE_MAINTAINER
    function fulfillMaintainerChangeProposal(uint256 index) external {
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );

        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        if (state.proposals[index].topic == Topic.ELECT_MAINTAINER) {
            state.maintainers[state.proposals[index].setMaintainerTo] = true;
            emit ProposalFulfilled(
                index,
                Topic.ELECT_MAINTAINER,
                MaintenanceTask.NONE
            );
        } else if (state.proposals[index].topic == Topic.REVOKE_MAINTAINER) {
            state.maintainers[state.proposals[index].setMaintainerTo] = false;
            emit ProposalFulfilled(
                index,
                Topic.REVOKE_MAINTAINER,
                MaintenanceTask.NONE
            );
        } else {
            revert("The proposal is not maintainer management");
        }
        state.proposals[index].status = Status.FULFILLED;

        lock = 0;
    }

    //Development voting fulfillment should result in a maintenance proposal
    function fulfillDevelopment(
        uint256 index,
        string calldata metadataUrl,
        Topic topic,
        MaintenanceTask maintenanceTask,
        bool setDisabledTo,
        address setAddressTo
    ) external {
        require(state.isMaintainer(msg.sender), "You are not a maintainer");
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be in accepted state"
        );
        require(lock == 0, "Function is busy,try again later");
        lock = 1;
        state.createProposal(
            msg.sender,
            metadataUrl,
            topic,
            maintenanceTask,
            0,
            address(0),
            setDisabledTo,
            setAddressTo
        );
        emit ProposalFulfilled(index, Topic.DEVELOPMENT, MaintenanceTask.NONE);
        lock = 0;
    }

    //Maintenance function evaluations will call external contract functions
    // disable value is used only if this is setDisabled, and address can be zero address in this case

    function fulfillMaintenance(uint256 index) external {
        require(state.isMaintainer(msg.sender), "You are not a maintainer");
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be in accepted state"
        );
        require(
            state.proposals[index].maintenanceTask != MaintenanceTask.NONE,
            "Maintenance task is not set"
        );
        require(lock == 0, "Function is busy,try again later");
        lock = 1;
        if (
            state.proposals[index].maintenanceTask ==
            MaintenanceTask.SETDISABLED
        ) {
            _factory.setDisabled(state.proposals[index].setDisabledTo);
            emit ProposalFulfilled(
                index,
                Topic.MAINTENANCE,
                MaintenanceTask.SETDISABLED
            );
        } else {
            if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETWORKSPACELIBRARY
            ) {
                _factory.setWorkSpaceLibrary(
                    state.proposals[index].setAddressTo
                );
                emit ProposalFulfilled(
                    index,
                    Topic.MAINTENANCE,
                    MaintenanceTask.SETWORKSPACELIBRARY
                );
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETJOBLIBRARY
            ) {
                _factory.setJobLibraryAddress(
                    state.proposals[index].setAddressTo
                );
                emit ProposalFulfilled(
                    index,
                    Topic.MAINTENANCE,
                    MaintenanceTask.SETJOBLIBRARY
                );
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETDIVIDENDSLIBRARY
            ) {
                _factory.setDividendsLibraryAddress(
                    state.proposals[index].setAddressTo
                );
                emit ProposalFulfilled(
                    index,
                    Topic.MAINTENANCE,
                    MaintenanceTask.SETDIVIDENDSLIBRARY
                );
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.WITHDRAWDIFFERENCE
            ) {
                _dividends.withdrawDifference(
                    state.proposals[index].setAddressTo
                );
                emit ProposalFulfilled(
                    index,
                    Topic.MAINTENANCE,
                    MaintenanceTask.WITHDRAWDIFFERENCE
                );
            }
        }

        state.proposals[index].status = Status.FULFILLED;
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

    function isMaintainer(address address_) external view returns (bool) {
        return state.maintainers[address_];
    }
}
