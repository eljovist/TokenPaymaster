// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;
pragma experimental ABIEncoderV2;

import { BasePaymaster } from "@opengsn/gsn/contracts/BasePaymaster.sol";
import { GSNTypes } from "@opengsn/gsn/contracts/utils/GSNTypes.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { GsnUtils } from "@opengsn/gsn/contracts/utils/GsnUtils.sol";

contract ERC20Paymaster is BasePaymaster {
    IERC20 token;
    bytes4 transferSelector;
    address public tokenReceiver;
    uint256 minAmount;

    event PreRelayed();
    event PostRelayed(bool success, uint actualCharge, bytes32 preRetVal);

    constructor(IERC20 _token, address _tokenReceiver, uint256 _minAmount) public {
        token = _token;
        tokenReceiver = _tokenReceiver;
        transferSelector = token.transfer.selector;
        minAmount = _minAmount;
    }

    function versionPaymaster() external view override virtual returns (string memory){
        return "1.0.0";
    }

    function acceptRelayedCall(
        GSNTypes.RelayRequest calldata relayRequest,
        bytes calldata signature,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
    external
    override
    view
    returns (bytes memory) {
        (approvalData, maxPossibleCharge);

        require(
            relayRequest.target == address(token),
            "ERC20Paymaster.acceptRelayedCall: RelayRecipient should be token"
        );

        bytes4 methodSig = GsnUtils.getMethodSig(relayRequest.encodedFunction);
        require(
            transferSelector == methodSig,
            "ERC20Paymaster.acceptRelayedCall: method should be transfer"
        );

        address to = GsnUtils.getAddressParam(relayRequest.encodedFunction, 0);
        require(
            tokenReceiver == to,
            "ERC20Paymaster.acceptRelayedCall: transfer to anyone is not allowed"
        );
        uint256 amount = GsnUtils.getParam(relayRequest.encodedFunction, 1);
        require(
            amount >= minAmount,
            "ERC20Paymaster.acceptRelayedCall: amount should bigger than minAmount"
        );

        return "";
    }

    function preRelayedCall(
        bytes calldata context
    )
    external
    override
    relayHubOnly
    returns (bytes32) {
        (context);
        emit PreRelayed();

        return bytes32(uint(0));
    }

    function postRelayedCall(
        bytes calldata context,
        bool success,
        bytes32 preRetVal,
        uint256 gasUseWithoutPost,
        GSNTypes.GasData calldata gasData
    )
    external
    override
    relayHubOnly
    {
        (context, gasUseWithoutPost, gasData);
        emit PostRelayed(success, gasUseWithoutPost, preRetVal);
    }
}