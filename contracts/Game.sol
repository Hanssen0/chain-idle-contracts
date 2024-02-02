// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {HugeNumLib, HugeNum} from "./utils/HugeNum.sol";
import {GameConstants} from "./GameConstants.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

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

contract Game is OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => PlayerStatus) public playersStatus;

    function initialize(address owner) external initializer {
        __Ownable_init(owner);
    }

    function _authorizeUpgrade(address newImpl) internal override onlyOwner {}

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

    function getPlayer(
        address player
    ) external view returns (PlayerStatus memory) {
        return playersStatus[player];
    }

    function initPlayer(HugeNum calldata blocksReq) external {
        PlayerStatus storage status = playersStatus[msg.sender];

        if (status.stage != PlayerStage.Uninitialized) {
            revert BadRequest();
        }

        HugeNum memory blocks = blocksReq;
        HugeNum memory initCost = GameConstants.getInitCost();
        if (blocks.gt(GameConstants.getInitLimit()) || initCost.gt(blocks)) {
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
        x.multiply(GameConstants.getXMultiplier());
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

        uint256 xLevel = status.xLevel;

        HugeNum memory cost = GameConstants.getXCostPerLevel();
        cost.multiply(HugeNumLib.fromUint(xLevel));

        HugeNum memory ideas = status.ideas;
        if (cost.gt(ideas)) {
            revert InsufficientIdeas();
        }
        ideas.dec(cost);
        status.ideas = ideas;
        unchecked {
            status.xLevel = xLevel + 1;
        }
    }
}
