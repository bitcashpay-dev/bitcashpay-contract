// SPDX-License-Identifier: MIT
pragma solidity >=0.4.21 <0.7.0;

import "./BitcashPay.sol";

import "./Ownable.sol";

contract BitcashPayStaking is Ownable{
    using SafeMath for uint256;
    

    /*****
    * @notice We usually require to know who are all the stakeholders.
    */
    address[] internal stakeholders;

    BitcashPay private BitcashPayToken;
    bool public stakingStatus;
    uint public minimumStake;

    constructor(BitcashPay _bitcashPayToken) public
    {
        BitcashPayToken = _bitcashPayToken;
        stakingStatus =  true;
        minimumStake = 10 ** 8;
        stakingLockDuration = 60;
    }


    function setStakingStatus(bool _status) public onlyOwner
    {
        stakingStatus = _status;
    }

    function setMinimumStake(uint _minimumStake) public onlyOwner
    {
        minimumStake = (_minimumStake * 10) ** 8;
    }

    modifier isStakingActive()
    {
        require(stakingStatus, "Cannot stake this time, Staking is offline");
        _;
    }

    uint private stakingLockDuration;

    function setStakingLockDuration(uint _days) public onlyOwner
    {
        stakingLockDuration = _days;
    }

    function getStakingLockDuration() public view
    returns (uint)
    {
        return stakingLockDuration;
    }

    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address)
        public
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            if (_address == stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
    function addStakeholder(address _stakeholder)
    internal
    {
        (bool _isStakeholder, ) = isStakeholder(_stakeholder);
        if(!_isStakeholder) stakeholders.push(_stakeholder);
    }

    /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
    function removeStakeholder(address _stakeholder)
    internal
    {
        (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
        if(_isStakeholder){
            stakeholders[s] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    /***
    * @notice The stakes for each stakeholder.
    */

    /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of wei staked.
    */
   function stakeOfAddressById(address _stakeholder, uint _id)
    public
    view
    returns(uint256)
    {
        return bcpStakes[_stakeholder][_id];
    }

    function stakesOfAddress(address _stakeholder)
    public view
    returns (uint)
    {
        uint256 _totalStakes = 0;
        for (uint s = 0; s < addressStakesIndexes[_stakeholder].length; s++) 
        {
            _totalStakes = _totalStakes.add(
                bcpStakes[_stakeholder][addressStakesIndexes[_stakeholder][s]]
            );
        }
        return _totalStakes;
    }


     /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
   function totalStakes()
        public
        view
        returns(uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < stakeholders.length; s += 1){
            for (uint i =0; i < addressStakesIndexes[stakeholders[s]].length; i++) {
                _totalStakes = _totalStakes.add(
                    bcpStakes[stakeholders[s]]
                        [addressStakesIndexes[stakeholders[s]][i]]
                );
            }
        }
        return _totalStakes;
    }

    mapping(address => mapping(uint => uint)) internal bcpStakes;
    mapping(address => mapping(uint => uint)) internal stakeExpirations;
    mapping(address => uint[]) internal addressStakesIndexes;
    mapping(address => mapping(uint => uint)) internal stakesLog;

    function getStakeExpiration(address _owner, uint _id) public view
    returns (uint)
    {
        return stakeExpirations[_owner][_id];
    }

    function getStakeHoldersCount() public view
    returns (uint)
    {
        return stakeholders.length;
    }

    event OnStake (address sender, uint stake_id, uint amount);

    /**
    * @notice A method for a stakeholder to create a stake.
    * @param _stake The size of the stake to be created.
    */
    function createStake(uint _stake, uint _id) isStakingActive
    public
    {
        require(_stake >= minimumStake, "Your staking doesn'\t meet the minimum amount to stake");
        require(BitcashPayToken.balanceOf(msg.sender) >= _stake, "Insufficient BCP to stake");
        
        require(BitcashPayToken.transferFrom(msg.sender, address(this), _stake), "Staking Failed due transfer failed");
        require(bcpStakes[msg.sender][_id] == 0, "Stake index is already in used");
        addStakeholder(msg.sender);
        bcpStakes[msg.sender][_id] = bcpStakes[msg.sender][_id].add(_stake);
        stakeExpirations[msg.sender][_id] = now + (stakingLockDuration * 24 * 60 * 60);
        stakesLog[msg.sender][_id] = now;
        addressStakesIndexes[msg.sender].push(_id);
        emit OnStake(msg.sender, _id, _stake);
    }
    

    event OnUnStake (address sender, uint stake_id, uint amount);
    /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
    function removeStake(uint _stake, uint _id)
    public
    {
        require(bcpStakes[msg.sender][_id] >= _stake, "Insufficient staked amount");
        require(stakeExpirations[msg.sender][_id] < now, "Staked token is currently locked.");
        bcpStakes[msg.sender][_id] = bcpStakes[msg.sender][_id].sub(_stake);
        
        if (bcpStakes[msg.sender][_id] == 0) {
            for (uint s = 0; s < addressStakesIndexes[msg.sender].length; s++){
                if (_id == addressStakesIndexes[msg.sender][s]) {
                    addressStakesIndexes[msg.sender][s] = addressStakesIndexes[msg.sender][addressStakesIndexes[msg.sender].length - 1];
                    addressStakesIndexes[msg.sender].pop();
                }
            }
        }
        uint availableRewards = getAvailableRewards(msg.sender, _id);
        
        require(BitcashPayToken.approve(address(this), _stake.add(availableRewards)), "Unstake failed due to fund approver failure");
        require(BitcashPayToken.transferFrom(address(this), msg.sender, _stake.add(availableRewards)), "Unstake failed due to failed transfer");
        emit OnUnStake(msg.sender, _id, _stake);
    }

    mapping (address => mapping(uint => uint)) internal claimedRewards;
    uint public minimumStakeAmount = 50000;
    uint public maxStakeAPR = 7;
    uint public minStakeAPR = 5;

    function setMinimumStakeAmount(uint _minimumStakeAmount) 
    public onlyOwner
    {
        minimumStakeAmount = _minimumStakeAmount;
    }

    function setMaximumStakeAPR(uint _APR) 
    public onlyOwner
    {
        maxStakeAPR = _APR;
    }

    function setMinimumStakeAPR(uint _APR) 
    public onlyOwner
    {
        minStakeAPR = _APR;
    }

    function calculateRewards(address _stakeholder, uint _id)
    public view
    returns (uint)
    {
        uint startOfStake = stakesLog[_stakeholder][_id];
        uint day = (24 * 60 * 60);
        uint daysPassed = ((now).sub(startOfStake)).div(day);
        uint MULTIPLIER = 10 ** 8;
        uint stakedAmount = stakeOfAddressById(_stakeholder, _id);
        uint calculatedReward = 0;
        if (stakedAmount > 0 && startOfStake != 0) {
            if (stakedAmount >= minimumStakeAmount.mul(MULTIPLIER)) {
                calculatedReward = stakedAmount * maxStakeAPR.mul(100) / 10000;
                calculatedReward = calculatedReward.div(365);
                return calculatedReward.mul(daysPassed);
            }
            calculatedReward = stakedAmount * minStakeAPR.mul(100) / 10000;
            calculatedReward = calculatedReward.div(365);
            return calculatedReward.mul(daysPassed);
        }
    }

    function getAvailableRewards(address _stakeholder, uint _id)
    public view
    returns (uint)
    {
        uint calculatedRewards = calculateRewards(_stakeholder, _id);
        return calculatedRewards - claimedRewards[_stakeholder][_id];
    }

    function getClaimedRewards(address _stakeholder, uint _id)
    public view
    returns (uint)
    {
        return claimedRewards[_stakeholder][_id];
    }

    event OnRewardClaim (address sender, uint stake_id, uint amount);

    function claimReward(uint _amount, uint _id)
    public
    {
        require(getAvailableRewards(msg.sender, _id) > _amount, "The amount you wish to claim exceeds the available rewards");
        require(BitcashPayToken.approve(address(this), _amount), "Unstake failed due to fund approval failure");
        require(BitcashPayToken.transferFrom(address(this), msg.sender, _amount), "Unstake failed due to failed transfer");
        claimedRewards[msg.sender][_id] = claimedRewards[msg.sender][_id].add(_amount);
        emit OnRewardClaim(msg.sender, _id, _amount);
    }

    event OnReStakeReward (address owner, uint stake_id, uint amount);

    function reStakeRewards(uint _amount, uint _id)
    public
    {
        require(getAvailableRewards(msg.sender, _id) > _amount, "The amount you wish to claim exceeds the available rewards");
        bcpStakes[msg.sender][_id] = bcpStakes[msg.sender][_id].add(_amount);
        claimedRewards[msg.sender][_id] = claimedRewards[msg.sender][_id].add(_amount);
        emit OnReStakeReward(msg.sender, _id, _amount);
    }

}