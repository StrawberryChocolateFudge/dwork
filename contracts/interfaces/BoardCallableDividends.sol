// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

//This defines the functions that get called by the board on the dividends contract

interface BoardCallableDividends {
    
    function withdrawDifference(address to)
        external
        returns (uint256 difference);
}
