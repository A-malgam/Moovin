pragma solidity ^0.4.21;
import "./ERC20.sol";

contract MOOVIN is TokenERC20 {
    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MOOVIN(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}
}