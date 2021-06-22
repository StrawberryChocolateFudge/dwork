// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
import "./DividendsLib.sol";


contract Dividends {
    event Received(address sender, uint256 value);

    using DividendsLib for DividendsState;
    DividendsState state;

    receive() external payable {
        if (msg.value > 0) {
            state.setTotalBalance(msg.value);
        }
        emit Received(msg.sender, msg.value);
    }

    fallback() external payable {
        if (msg.value > 0) {
            state.setTotalBalance(msg.value);
        }
        emit Received(msg.sender, msg.value);
    }
}
