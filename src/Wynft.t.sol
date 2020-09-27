pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./Wynft.sol";

contract WynftTest is DSTest {
    Wynft wynft;

    function setUp() public {
        wynft = new Wynft();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
