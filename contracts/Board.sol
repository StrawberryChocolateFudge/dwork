// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/RoleLib.sol";
import "./libraries/BoardLib.sol";
import "./WorkSpaceFactory.sol";
import "./Dividends.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/BoardCallableFactory.sol";
import "./interfaces/BoardCallableDividends.sol";

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
        bytes32 identifier,
        Topic topic,
        MaintenanceTask maintenanceTask
    );

    event Vote(address voter, uint256 to, bool ticket, uint256 weight);
    //TODO: More events!

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
        address firstMaintainer
    ) {
        _token = token_;
        _factory = factory_;
        state.maintainers[firstMaintainer] = true;
    }

    //The identifier must be computed on the front end
    function createProposal(
        string calldata metadataUrl,
        bytes32 identifier,
        Topic topic,
        MaintenanceTask maintenanceTask
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
            identifier,
            topic,
            maintenanceTask
        );
        emit ProposalCreated(
            msg.sender,
            metadataUrl,
            identifier,
            topic,
            maintenanceTask
        );
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
            state.proposals[index].status == Status.STARTED,
            "The proposal already closed"
        );
        require(
            state.proposals[index].atBlock + expiryTime < block.number,
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
        lock = 0;
    }

    // These accepted proposals can be fulfilled by anyone
    //  FEE_CHANGE
    function fulfillFeeChangeProposal(uint256 index, uint16 newFee) external {
        require(
            state.proposals[index].topic == Topic.FEE_CHANGE,
            "Proposal must be Fee change"
        );
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );
        require(newFee <= 1000, "521");
        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        bytes32 identifier = getFeeChangeIdentifier(
            state.proposals[index].creator,
            newFee,
            state.proposals[index].metadataUrl
        );
        require(
            state.proposals[index].identifier == identifier,
            "The identifiers don't match, you are calling the function with the wrong argument"
        );

        _factory.setContractFee(newFee);

        lock = 0;
    }

    // ELECT_MAINTAINER
    // REVOKE_MAINTAINER
    function fulfillMaintainerChangeProposal(uint256 index, address maintainer)
        external
    {
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be accepted"
        );
        require(maintainer != address(0), "Maintainer address is zero address");

        require(
            state.proposals[index].identifier ==
                getMaintainerChangeIdentifier(
                    state.proposals[index].creator,
                    maintainer,
                    state.proposals[index].topic
                ),
            "Identifier is wrong"
        );
        require(lock == 0, "Function is busy,try again later");
        lock = 1;

        if (state.proposals[index].topic == Topic.ELECT_MAINTAINER) {
            state.maintainers[maintainer] = true;
        } else if (state.proposals[index].topic == Topic.REVOKE_MAINTAINER) {
            state.maintainers[maintainer] = false;
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
        bytes32 identifier,
        Topic topic,
        MaintenanceTask maintenanceTask
    ) external {
        require(state.isMaintainer(msg.sender), "You are not a maintainer");
        require(
            state.proposals[index].status == Status.ACCEPTED,
            "Proposal must be in accepted state"
        );
        require(
            state.proposals[index].identifier ==
                getDevelopmentProposalIdentifier(
                    state.proposals[index].creator,
                    topic,
                    state.proposals[index].metadataUrl,
                    maintenanceTask
                ),
            "Identifier dont match"
        );
        //If the identifier match, the maintainer can mark this fulfilled and create a maintenance proposal
        require(lock == 0, "Function is busy,try again later");
        lock = 1;
        state.createProposal(
            msg.sender,
            metadataUrl,
            identifier,
            topic,
            maintenanceTask
        );
        emit ProposalCreated(
            msg.sender,
            metadataUrl,
            identifier,
            topic,
            maintenanceTask
        );
        lock = 0;
    }

    //Maintenance function evaluations will call external contract functions
    // disable value is used only if this is setDisabled, and address can be zero address in this case

    function fulfillMaintenance(
        uint256 index,
        bool disableValue,
        address to
    ) external {
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
        //TODO: REFACTOR TO REMOVE SUCH CODE REPETITION LIKE THE VALIDATION
        if (
            state.proposals[index].maintenanceTask ==
            MaintenanceTask.SETDISABLED
        ) {
            require(
                state.proposals[index].identifier ==
                    getDisableFactoryIdentifier(
                        state.proposals[index].creator,
                        disableValue
                    ),
                "The identifier is not correct"
            );
            _factory.setDisabled(disableValue);
        } else {
            require(to != address(0), "Cannot be address zero");
            require(
                state.proposals[index].identifier ==
                    getAddressSettingIdentifier(
                        state.proposals[index].creator,
                        to,
                        state.proposals[index].topic
                    ),
                "The identifier is not correct"
            );
            if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETWORKSPACELIBRARY
            ) {
                _factory.setWorkSpaceLibrary(to);
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETJOBLIBRARY
            ) {
                _factory.setJobLibraryAddress(to);
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.SETDIVIDENDSLIBRARY
            ) {
                _factory.setDividendsLibraryAddress(to);
            } else if (
                state.proposals[index].maintenanceTask ==
                MaintenanceTask.WITHDRAWDIFFERENCE
            ) {
                _dividends.withdrawDifference(to);
            }
        }

        state.proposals[index].status = Status.FULFILLED;
        lock = 0;
    }

    function hasEnoughShares(address sender) internal view returns (bool) {
        return
            _token.balanceOf(sender) >
            _token.totalSupply() / enoughSharesDivideBy;
    }

    // The identifier hashing functions are available as public functions
    // They are called internally but the front end can
    // call them to get hash the identifier too
    function getFeeChangeIdentifier(
        address creator,
        uint16 newFee,
        string memory metadataUrl
    ) public pure returns (bytes32 result) {
        result = keccak256(abi.encodePacked(creator, newFee, metadataUrl));
    }

    function getMaintainerChangeIdentifier(
        address creator,
        address maintainer,
        Topic topic
    ) public pure returns (bytes32 result) {
        require(
            topic == Topic.ELECT_MAINTAINER || topic == Topic.REVOKE_MAINTAINER,
            "Wrong topic"
        );
        result = keccak256(abi.encodePacked(creator, maintainer, topic));
    }

    function getDisableFactoryIdentifier(address creator, bool _disabled)
        public
        pure
        returns (bytes32 result)
    {
        result = keccak256(abi.encodePacked(creator, _disabled));
    }

    function getAddressSettingIdentifier(
        address creator,
        address to,
        Topic topic
    ) public pure returns (bytes32 result) {
        result = keccak256(abi.encodePacked(creator, to, topic));
    }

    function getDevelopmentProposalIdentifier(
        address creator,
        Topic topic,
        string memory metadataUrl,
        MaintenanceTask task
    ) public pure returns (bytes32 result) {
        result = keccak256(abi.encodePacked(creator, topic, metadataUrl, task));
    }
}
