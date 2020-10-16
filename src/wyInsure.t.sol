pragma solidity ^0.5.0;

import "ds-test/test.sol";

import "./wyInsure.sol";

contract wyInsureTest is DSTest {
    wyInsure wyi;

    function setUp() public {
        wyi = new wyInsure();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
