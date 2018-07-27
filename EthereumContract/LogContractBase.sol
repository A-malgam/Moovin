pragma solidity ^0.4.21;

contract LogContractBase {

    event Trace(string severite, string source, string message);


    function WriteLog(string severite,string source, string message) internal {
        emit Trace(severite,source,message);
    }

    function uintToString(uint num1) internal pure returns (string) {
        uint num = num1;
        if(num == 0) {
            return "0";
        }

        uint tmpNum = num;
        uint length;
        while (tmpNum != 0) {
            length++;
            tmpNum /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint count = length - 1;
        while (num != 0) {
            bstr[count--] = byte(48 + num % 10);
            num /= 10;
        }
        return string(bstr);
    }

    function uint256ToString(uint256 num1) internal pure returns (string) {
        uint256 num = num1;
        if(num == 0) {
            return "0";
        }

        uint256 tmpNum = num;
        uint length;
        while (tmpNum != 0) {
            length++;
            tmpNum /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint count = length - 1;
        while (num != 0) {
            bstr[count--] = byte(48 + num % 10);
            num /= 10;
        }
        return string(bstr);
    }

    function boolToString(bool value) internal pure returns (string) {
        if(value) {
            return "true";
        }
        else{
            return "false";
        }
    }

    function ToAsciiString(address x) internal pure returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(x) / (2**(8*(19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(byte b) internal pure returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }
}