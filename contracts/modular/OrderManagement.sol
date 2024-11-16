// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ManufacturerManagement.sol";

contract OrderManagement {
    // in situation where users are ordering for items
    // of different batches.

    struct OrderItem {
        uint256 batchId;
        uint256 quantity;
        OrderLog[] orderlog;
    }

    UserRoleManager public userRoleManager;
    ManufacturerManagement public manufacturerManagement;

    constructor(
        address _userRoleAddress,
        address _manufacturerManagementAddress
    ) {
        userRoleManager = UserRoleManager(_userRoleAddress);
    }

    struct OrderLog {
        UserRoleManager.userRole userRole;
        OrderStatus orderStatus;
    }

    enum OrderStatus {
        DISPATCHED,
        DELIVERED_TO_RETAILER,
        RECEIVED_BY_RETAILER,
        IN_TRANSIT_TO_LOGISTICPERSONNEL,
        IN_TRANSIT_TO_RETAILER,
        WITH_RETAILER,
        SOLD_TO_CONSUMER,
        RETURNED,
        RECALLED,
        AVAILABLE_FOR_SALE
    }

    struct Order {
        //reatiler can order, customer can order
        address whoOrders;
        // array of Items in Order
        OrderItem[] items;
        OrderStatus status;
        string overallStatus;
    }

    function requestOrder(
        uint256 _batchId,
        uint256 _quantity
    ) external payable returns(uint256 orderId) {
        require(_quantity > 0, "Quantity  Must be greater than 0");

        orderId = uint256(
            keccak256(abi.encodePacked(msg.sender, batchId, block.timestamp))
        );
        emit OrderRequested(msg.sender, msg.value, orderId, batchId, quantity);
        return orderId;
    }

    function approveOrder(uint256 _orderId, address _retailer) external {
      

    }
}
