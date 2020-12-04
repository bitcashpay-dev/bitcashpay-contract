// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./BitcashPay.sol";

contract BitcashPayTokenPreSale {

    using SafeMath for uint;

    address payable owner;
    BitcashPay public bcpTokenContract;
    uint public tokensSold;

    uint public constant saleCap         =           15000;
    
    uint private constant MULTIPLIER     =           100000000;
    uint private sale_bonus              =           0;

    constructor(BitcashPay _tokenContract) public {
        owner = msg.sender;
        bcpTokenContract = _tokenContract;
    }

    modifier ownerOnly {
        if (msg.sender != owner && msg.sender != address(this)) revert("Access Denied!");
        _;
    }

    function setSaleBonus(uint bonus_rate) public ownerOnly returns (bool success){
        sale_bonus = bonus_rate;
        return true;
    }

    function transferEther(address payable _to, uint _amount) public ownerOnly returns (bool success)
    {
        uint amount = _amount * 10 ** 18;
        _to.transfer(amount.div(1000));
        return true;
    }

    event Sold(address _from, address _to, uint _amount);

    function buyBitcashPayAgainstEther(address payable _sender, uint _amount) public returns (bool success) {
        uint token_sold = bcpTokenContract.buyBitcashPayAgainstEther(_sender, _amount);
        

        if (token_sold.div(MULTIPLIER) >= 5000 && saleCap > tokensSold) {
            uint bonus = token_sold.div(2);
            bcpTokenContract.getBonus(_sender, bonus);
        } else {
            if (sale_bonus != 0) {
                uint bonus = token_sold.div(sale_bonus);
                bcpTokenContract.getBonus(_sender, bonus);
            }
        }

        tokensSold += token_sold.div(MULTIPLIER);

        return true;
    }

    event Received(address _from, uint _amount);

    receive() external payable {
        if (msg.sender != owner) {
            buyBitcashPayAgainstEther(msg.sender, msg.value);
        }
        emit Received(msg.sender, msg.value);
    }

}