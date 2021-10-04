# Board

## Description

The Board is for voting. The DWORK token holders can propose the fees that will be used in future job escrows.
The board does an importand work and may have influence on the token pricing.

## Public API
`createProposal(uint16 setFeeTo) external`

A wallet with anough shares( DWORK) can create a proposal to set the fee

`vote(uint256 to, bool ticket)`

A DWORK token holder can vote. ${to} determines the index of the proposal, the ticket is the yes or no vote.
The weight of the vote is determined by the DWORk the voter holds. If a user claims dividends, while his tokens are locked he looses voting power.

`closeVoting(uint256 index) external`

If the voting period expired, anyone can call the close function.
This will close the voting stored at index.

`fulfillProposal(uint256 index) external`
The fulfill function of the proposal can be called by anyone if the proposal was evaluated to accepted during closing

## PUBLIC VIEW FUNCTIONS

`getLastProposalIndex() external view returns (uint256)`

Gets the index of the last proposal

`getProposals(uint256 index)
        external
        view
        returns (Proposals memory)`

Gets the proposal at index

`getVotes(uint256 index) external view returns (uint256, uint256)`

Gets the amount of votes, returns a tupple (yes,no)

`votedAlready(uint256 index, address _voter)
        external
        view
        returns (bool)`

The sender can verify if he voted already