# DLink

## Description

This is a utility contract that links addresses.
Used for storing workspace addresses per wallet, to save where the user has workspaces or roles in one

## Public API

`link(address[] memory workspaces) external returns (uint256)`

You save the workspaces (all) associated with the user currently and saves them indexed


## Public View functions
`getLinks() external view returns (address[] memory)`

Returns all the workspace addresses associated to the sender address

`getCounter() external view returns (uint256)`

Returns the last index from the counter, for a sender

`getHistory(uint256 indx) external view returns (address[] memory)`

Returns the workspaces in history at a certain index fetched by getCounter
