// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HugeNumLib, HugeNum} from "./utils/HugeNum.sol";

using HugeNumLib for HugeNum;

// enum
library PlayerStage {
    uint constant Uninitialized = 0;
    uint constant Multiplier = 1;
}

struct PlayerStatus {
    uint lastTimestamp;
    uint stage; // PlayerStage
    HugeNum blocks;
    HugeNum ideas;
    uint dt;
    uint xLevel;
}

error BadRequest();
error InsufficientIdeas();

contract Game {
    HugeNum INIT_LIMIT;
    HugeNum INIT_COST;
    HugeNum X_MULTIPLIER;
    HugeNum X_COST_PER_LEVEL;

    mapping(address => PlayerStatus) public playersStatus;

    constructor() {
        INIT_LIMIT.mantissa = HugeNumLib.ONE_N;
        INIT_LIMIT.depth = 1;
        INIT_LIMIT.exponent = 6 * HugeNumLib.ONE_N;

        INIT_COST.mantissa = (45 * HugeNumLib.ONE_N) / 10;
        INIT_COST.depth = 1;
        INIT_COST.exponent = 4 * HugeNumLib.ONE_N;

        X_MULTIPLIER.mantissa = 5 * HugeNumLib.ONE_N;
        X_MULTIPLIER.depth = 1;
        X_MULTIPLIER.exponent = 1 * HugeNumLib.ONE_N;

        X_COST_PER_LEVEL.mantissa = HugeNumLib.ONE_N;
        X_COST_PER_LEVEL.depth = 1;
        X_COST_PER_LEVEL.exponent = 3 * HugeNumLib.ONE_N;
    }

    function assertInitedPlayer()
        internal
        view
        returns (PlayerStatus storage status)
    {
        status = playersStatus[msg.sender];
        if (status.stage == PlayerStage.Uninitialized) {
            revert BadRequest();
        }
    }

    function getPlayer(address player) external view returns (PlayerStatus memory) {
        return playersStatus[player];
    }

    function initPlayer(HugeNum calldata blocksReq) external {
        PlayerStatus storage status = playersStatus[msg.sender];

        if (status.stage != PlayerStage.Uninitialized) {
            revert BadRequest();
        }

        HugeNum memory blocks = blocksReq;
        if (blocks.gt(INIT_LIMIT)) {
            revert BadRequest();
        }

        HugeNum memory initCost = INIT_COST;
        if (initCost.gt(blocks)) {
            revert BadRequest();
        }

        status.blocks = blocks;

        blocks.dec(initCost);
        status.ideas = blocks;

        status.stage = PlayerStage.Multiplier;
        status.lastTimestamp = block.timestamp;
        status.dt = 1;
        status.xLevel = 10;
    }

    function _updateBlocks(PlayerStatus storage status) internal {
        HugeNum memory x = HugeNumLib.fromUint(status.xLevel);
        x.multiply(X_MULTIPLIER);
        x.multiply(
            HugeNumLib.fromUint(
                (block.timestamp - status.lastTimestamp) * status.dt
            )
        );

        HugeNum memory blocks = status.blocks;
        blocks.inc(x);
        status.blocks = blocks;

        x.inc(status.ideas);
        status.ideas = x;

        status.lastTimestamp = block.timestamp;
    }

    function updateBlocks() external {
        PlayerStatus storage status = assertInitedPlayer();
        _updateBlocks(status);
    }

    function purchaseX() external {
        PlayerStatus storage status = assertInitedPlayer();
        if (status.lastTimestamp == block.timestamp) {
            revert BadRequest();
        }

        _updateBlocks(status);

        HugeNum memory cost = X_COST_PER_LEVEL;
        cost.multiply(HugeNumLib.fromUint(status.xLevel));

        HugeNum memory ideas = status.ideas;
        if (cost.gt(ideas)) {
            revert InsufficientIdeas();
        }
        ideas.dec(cost);
        status.ideas = ideas;
        unchecked {
            status.xLevel += 1;
        }
    }
}
