// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./BitcashPay.sol";
import "./Ownable.sol";

contract BitcashPayAirdropper is Ownable
{
    using SafeMath for uint256;

    BitcashPay private BitcashPayToken;
    bool public airdropperStatus;

    constructor(BitcashPay _bitcashPayToken) public
    {
        BitcashPayToken = _bitcashPayToken;
        airdropperStatus = false;
    }

    function setAirdropperStatus(bool _status) public onlyOwner
    {
        airdropperStatus = _status;
    }

    function setAirdropperAllowance(uint _allowance) public onlyOwner
    {
        require(BitcashPayToken.approve(address(this), _allowance), "Unstake failed due to fund approver failure");
    }

    mapping (address => uint) public totalClaimedAidropByAddress;
    uint public totalClaimedAirdrops;

    event OnAirdropSend (uint amount, address recipient);

    function sendAirdrop(uint _amount, address _recipient) public onlyOwner
    {
        require(airdropperStatus, "Airdopper is currently disabled.");
        require(BitcashPayToken.allowance(0xB390d9cE1c553D3b531E2fb9B8186Da6C28e3235, owner) >= _amount, "Airdropper doesn't have enough tokens to send");
        require(BitcashPayToken.transferFrom(address(this), _recipient, _amount), "Airdrop Failed due transfer failed");
        totalClaimedAirdrops += _amount;
        totalClaimedAidropByAddress[_recipient] = totalClaimedAidropByAddress[_recipient].add(_amount);
        emit OnAirdropSend(_amount, _recipient);
    }

    function getClaimedAirdropByAddress(address _address) public view
    returns (uint)
    {
        return totalClaimedAidropByAddress[_address];
    }
}