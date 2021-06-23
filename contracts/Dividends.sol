// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./DividendsLib.sol";
import "./DWorkToken.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Dividends is  Initializable  {
    event Received(address sender, uint256 value);

    using DividendsLib for DividendsState;
    DividendsState state;

    //Users must be able to lock tokens and receive dividends
    //The dividends payout periods are calculated by block.number % 1.000.000 , 
    //Every 1 millionth block will be a new cycle

    // constructor(uint256 nonce){
    //     state.cycleNonce = nonce;
    // }
    
    function initialize() external  initializer() {}
  

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
