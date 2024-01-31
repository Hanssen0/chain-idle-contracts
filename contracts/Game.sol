// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HugeNumLib} from "./utils/HugeNum.sol";

contract Game {
    struct PlayerStatus {
        HugeNumLib.HugeNum blocks;
        HugeNumLib.HugeNum ideas;
        uint256 xLevel;
    }

    mapping(address => PlayerStatus) public playersStatus;
}
