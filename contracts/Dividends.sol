// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "./DividendsLib.sol";
import "./DWorkToken.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Dividends is Initializable, ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using DividendsLib for DividendsState;

    event Received(address sender, uint256 value);
    event Claim(address sender, uint256 value, uint256 with);
    event TokenWithdraw(address recepient, uint256 value, uint256 index);
    event Reclaim(address claimer, uint256 value, uint256 with);
    DividendsState state;
    IERC20 _token;
    //one cycle has 1 million blocks, after 1 million blocks the tokens can be redeemed or reinvested
    uint256 _cycle;

    //Users must be able to lock tokens and receive dividends
    //The dividends payout periods are calculated by block.number % 1.000.000 ,
    //Tokens are unlockable after that period

    constructor(IERC20 token_, uint256 cycle_) {
        _token = token_;
        _cycle = cycle_;
    }

    receive() external payable {
        //The dividends is  ether, sent by Job contracts as fee
        if (msg.value > 0) {
            state.setTotalBalance(msg.value);
            state.setCurrentBalance(msg.value, Change.Add);
        }
        emit Received(msg.sender, msg.value);
    }

    function claimDividends(uint256 amount) external nonReentrant {
        state.setManagedTokens(amount, Change.Add);
        _processRequest(amount, msg.sender);
    }

    function _processRequest(uint256 amount, address sender) internal {
        require(_token.balanceOf(sender) >= amount, "Not enough balance");
        state.setNewBalance(sender, amount);
        uint256 payment = calculateDividends(amount);
        _token.safeTransferFrom(sender, address(this), amount);
        Address.sendValue(payable(sender), payment);
        state.setCurrentBalance(payment, Change.Withdraw);
        emit Claim(sender, payment, amount);
    }

    function _processReclaim(uint256 amount, address sender) internal {
        state.setNewBalance(sender, amount);
        uint256 payment = calculateDividends(amount);
        Address.sendValue(payable(sender), payment);
        state.setCurrentBalance(payment, Change.Withdraw);
        emit Reclaim(msg.sender, payment, amount);
    }

    function calculateDividends(uint256 amount)
        public
        view
        returns (uint256 payment)
    {
        // This is public so can be called internally and externally too
        uint256 withPadding = amount * precision;
        uint256 dividedByTotal = (withPadding / _token.totalSupply());
        uint256 calculatedValue = dividedByTotal * state.currentBalance;
        payment = calculatedValue / precision;
    }

    //Abstract the requires to function call
    function withdrawToken(uint256 index) external nonReentrant {
        (bool valid, string memory err) = state.verify(
            index,
            msg.sender,
            _cycle
        );
        require(valid, err);
        state.tokenBalances[msg.sender][index].state = BalanceState.Withdrawn;

        _token.safeTransfer(
            msg.sender,
            state.tokenBalances[msg.sender][index].balance
        );

        state.setManagedTokens(
            state.tokenBalances[msg.sender][index].balance,
            Change.Withdraw
        );

        emit TokenWithdraw(
            msg.sender,
            state.tokenBalances[msg.sender][index].balance,
            index
        );
    }

    //abstract requires to function call
    function reclaimDividends(uint256 index) external nonReentrant {
        (bool valid, string memory err) = state.verify(
            index,
            msg.sender,
            _cycle
        );
        require(valid, err);
        state.tokenBalances[msg.sender][index].state = BalanceState.Reclaimed;
        
        _processReclaim(
            state.tokenBalances[msg.sender][index].balance,
            msg.sender
        );
    }

    function withdrawDifference(address to)
        external
        nonReentrant
        onlyOwner
        returns (uint256 difference)
    {
        // I can recover if somebody sent extra tokens by accident
        // without calling the getDividends function
        // This shouldn't happen often, hopefully never
        difference = _token.balanceOf(address(this)) - state.managedTokens;
        if (difference != 0) {
            _token.safeTransferFrom(address(this), to, difference);
        }
    }

    function getManagedTokens() external view returns (uint256) {
        return state.managedTokens;
    }

    function getTotalBalance() external view returns (uint256) {
        return state.totalBalance;
    }

    function getCurrentBalance() external view returns (uint256) {
        return state.currentBalance;
    }

    function getCurrentIndex() external view returns (uint256) {
        return state.indexes[msg.sender];
    }

    function getHistory(uint256 index) external view returns (Balance memory) {
        return state.tokenBalances[msg.sender][index];
    }
}
