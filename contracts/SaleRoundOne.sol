// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./BitcashPay.sol";

contract BitcashPaySaleRoundOne{

    using SafeMath for uint;

    address payable owner;
    BitcashPay public bcpTokenContract;
    uint public tokensSold;

    uint public constant saleCap         =           200000000;
    
    uint private constant MULTIPLIER     =           100000000;

    constructor(BitcashPay _tokenContract) public {
        owner = msg.sender;
        bcpTokenContract = _tokenContract;
    }

    modifier ownerOnly {
        if (msg.sender != owner && msg.sender != address(this)) revert("Access Denied!");
        _;
    }

    function transferEther() public ownerOnly returns (bool success)
    {
        owner.transfer(address(this).balance);
        return true;
    }

    event Sold(address _from, address _to, uint _amount);

    function buyBitcashPayAgainstEther(address payable _sender, uint _amount) public returns (uint amount_sold) {
        require(tokensSold < saleCap, "There's is no enough token for sale");
        uint token_sold = bcpTokenContract.buyBitcashPayAgainstEther(_sender, _amount);

        
        uint bonus = token_sold.div(5);
        bcpTokenContract.getBonus(_sender, bonus);
        

        tokensSold += token_sold.div(MULTIPLIER);

        return token_sold;
    }

    event Received(address _from, uint _amount);

    receive() external payable {
        if (msg.sender != owner) {
            buyBitcashPayAgainstEther(msg.sender, msg.value);
        }
        emit Received(msg.sender, msg.value);
    }
}