// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HugeNumLib, HugeNum} from "./utils/HugeNum.sol";

library GameConstants {
    int256 private constant INIT_LIMIT_EXPONENT = 6 * HugeNumLib.ONE_N;

    function getInitLimit() internal pure returns (HugeNum memory res) {
        res.mantissa = HugeNumLib.ONE_N;
        res.depth = 1;
        res.exponent = INIT_LIMIT_EXPONENT;
    }

    int256 private constant INIT_COST_MANTISSA = (45 * HugeNumLib.ONE_N) / 10;
    int256 private constant INIT_COST_EXPONENT = 4 * HugeNumLib.ONE_N;
    function getInitCost() internal pure returns (HugeNum memory res) {
        res.mantissa = INIT_COST_MANTISSA;
        res.depth = 1;
        res.exponent = INIT_COST_EXPONENT;
    }

    int256 private constant X_MULTIPLIER_MANTISSA = 5 * HugeNumLib.ONE_N;
    function getXMultiplier() internal pure returns (HugeNum memory res) {
        res.mantissa = X_MULTIPLIER_MANTISSA;
        res.depth = 1;
        res.exponent = HugeNumLib.ONE_N;
    }

    int256 private constant X_COST_PER_LEVEL_EXPONENT = 3 * HugeNumLib.ONE_N;
    function getXCostPerLevel() internal pure returns (HugeNum memory res) {
        res.mantissa = HugeNumLib.ONE_N;
        res.depth = 1;
        res.exponent = X_COST_PER_LEVEL_EXPONENT;
    }
}
