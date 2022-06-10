// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Greeting {
    string public greeter;

    function setGreeter(string calldata _greet) external {
        greeter = _greet;
    }
}
