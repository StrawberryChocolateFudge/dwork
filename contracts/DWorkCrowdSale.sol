// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./RoleLib.sol";

//This is based on the openzeppelin crowdsale contract from 2.x
contract DWorkCrowdSale is Context, ReentrancyGuard, AccessControl {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 private _token;

    //The address where funds are collected
    address payable private _wallet;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    //DWork is 1^18 like Eth
    uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    //Each address can only purchase 10.000 tokens maximum
    uint256 constant maxPurchase = 10000 ether;
    mapping(address => uint256) purchases;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    event TokensWithdrawn(address to, uint256 value);

    constructor(
        uint256 rate_,
        address payable wallet_,
        IERC20 token_,
        address admin
    ) {
        require(rate_ > 0, "Rate is zero");
        require(wallet_ != address(0), "Wallet is zero address");
        require(address(token_) != address(0), "Token is the zero address");
        _rate = rate_;
        _wallet = wallet_;
        _token = token_;
        _setupRole(RoleLib.ADMIN_ROLE, admin);
    }

    receive() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function rate() public view returns (uint256) {
        return _rate;
    }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable nonReentrant {
        uint256 weiAmount = msg.value;
        require(beneficiary != address(0), "Beneficiary is the zero address");
        require(weiAmount != 0, "WeiAmount is 0");
        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);

        if (purchases[_msgSender()] != 0) {
            // If the address made a purchase before
            //It can only buy tokens if the purchase is smaller or equals the maximum
            require(purchases[_msgSender()] + tokens <= maxPurchase);
            // I add the tokens to track purchases
            purchases[_msgSender()] += tokens;
        }

        // update state
        _weiRaised = _weiRaised.add(weiAmount);
        // Transfers the tokens for the beneficialy
        _token.safeTransfer(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount, tokens);
        // Forwards the funds
        _wallet.transfer(msg.value);
    }

    function _getTokenAmount(uint256 weiAmount)
        internal
        view
        returns (uint256)
    {
        return weiAmount.mul(_rate);
    }

    function adminTransfer(uint256 value, address to)
        external
        nonReentrant
        onlyRole(RoleLib.ADMIN_ROLE)
    {
	//The admin can withdraw the tokens to any address
        _token.safeTransfer(to, value);
        emit TokensWithdrawn(to, value);
    }
}
