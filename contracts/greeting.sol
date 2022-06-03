// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

contract Greeting {
    string public greeter;

    function setGreeter(string memory _greet) external {
        greeter = _greet;
    }
}
