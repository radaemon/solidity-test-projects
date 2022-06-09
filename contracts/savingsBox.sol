// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SavingsBox is Ownable {
    using SafeMath for uint;

    address public charity;
    uint public constant SECONDS_IN_PERIOD = 30 days;
    uint public constant CONTRACT_DURATION = 52 weeks;
    uint public CONTRACT_DEPLOYED = block.timestamp;
    uint public constant PERCENT_LOST_PER_LATE_PAYMENT = 5;

    mapping(address => uint) public addressToIndex;
    Saver[] public savers;

    struct Saver {
        uint topPayment;
        uint balance;
        uint latePayments;
        uint lastPayment;
        bool exists;
    }

    constructor(address _charity) {
        charity = _charity;
    }

    function _adjustLatePayments(Saver storage saver) private {
        require(saver.exists == true, "saver does not exist.");

        bool isLate = block.timestamp > saver.lastPayment + SECONDS_IN_PERIOD
            ? true
            : false;

        if (!isLate) return;

        uint secondsLate = block.timestamp -
            (saver.lastPayment + SECONDS_IN_PERIOD);
        uint periodsLate = secondsLate / SECONDS_IN_PERIOD;

        saver.latePayments = saver.latePayments.add(periodsLate);
    }

    function deposit(address saver) public payable returns (uint) {
        // Look up address (0 means user does not exist)
        uint saverIndex = addressToIndex[saver];

        // new user
        if (saverIndex == 0) {
            // push to array
            savers.push(Saver(msg.value, msg.value, 0, block.timestamp, true));
            // link the address with the array index
            addressToIndex[saver] = savers.length;
            // return the balance of the saver
            return savers[addressToIndex[saver].sub(1)].balance;
        }

        Saver storage existingSaver = savers[saverIndex.sub(1)];
        // user required to deposit >= of his top payment
        require(
            msg.value >= existingSaver.topPayment,
            "Must deposit allowance >= topPayment"
        );

        // add the value to his balance
        uint newBalance = existingSaver.balance.add(msg.value);
        existingSaver.balance = newBalance;

        // if the deposit is > than his last topPayment then
        // adjust topPayment
        if (msg.value > existingSaver.topPayment) {
            existingSaver.topPayment = msg.value;
        }

        // check for late payments
        _adjustLatePayments(existingSaver);

        // reset savers last payment
        existingSaver.lastPayment = block.timestamp;

        return newBalance;
    }

    function withdraw(address retiree) public afterTimePeriods {
        // GET USER
        Saver storage saver = savers[addressToIndex[retiree].sub(1)];

        require(saver.exists == true, "User does not exist");

        _adjustLatePayments(saver);

        // calculate how much goes to charity based on late payments
        uint userBalance = saver.balance;
        uint latePayments = saver.latePayments;

        uint percentageForCharity = latePayments *
            PERCENT_LOST_PER_LATE_PAYMENT;
        uint percentageForUser = 100 - percentageForCharity;

        // set user balance to 0
        saver.balance = 0;
        saver.exists = false;

        // transfer to user and charity
        payable(retiree).transfer((userBalance * percentageForUser) / 100);
        payable(charity).transfer((userBalance * percentageForCharity) / 100);
    }

    function changeCharity(address newCharity) public onlyOwner {
        charity = newCharity;
    }

    modifier afterTimePeriods() {
        // check if the time periods have elapsed
        require(
            block.timestamp >= CONTRACT_DEPLOYED + CONTRACT_DURATION,
            "contract has not expired."
        );
        _;
    }
}
