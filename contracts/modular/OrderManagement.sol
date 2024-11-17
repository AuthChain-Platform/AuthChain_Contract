// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ManufacturerManagement.sol";
import "../lib/event.sol";

contract OrderManagement {
    UserRoleManager public userRoleManager;
    ManufacturerManagement public manufacturerManagement;

    constructor(
        address _userRoleAddress,
        address _manufacturerManagementAddress
    ) {
        userRoleManager = UserRoleManager(_userRoleAddress);
    }

    // in situation where users are ordering for items
    // of different batches.

    struct OrderItem {
        uint256 batchId;
        uint256 quantity;
        OrderLog[] orderlog;
    }

    struct OrderLog {
        UserRoleManager.userRole userRole;
        OrderStatus orderStatus;
    }

    enum OrderStatus {
        AVAILABLE_FOR_SALE,
        ORDER_APPROVED,
        DISPATCHED,
        DELIVERED_TO_RETAILER,
        RECEIVED_BY_RETAILER,
        IN_TRANSIT_TO_LOGISTICPERSONNEL,
        IN_TRANSIT_TO_RETAILER,
        WITH_RETAILER,
        SOLD_TO_CONSUMER,
        RETURNED,
        RECALLED
    }

    struct Order {
        address whoOrders;
        OrderItem[] items;
        OrderStatus status;
        string overallStatus;
        uint256 durationOfOrderCreation;
    }

    mapping(uint256 => Order) public orders;

    function requestOrder(
        uint256 _batchId,
        uint256 _quantity
    ) external payable returns (uint256 orderId) {
        require(_quantity > 0, "Quantity  Must be greater than 0");

        orderId = uint256(
            keccak256(abi.encodePacked(msg.sender, batchId, block.timestamp))
        );
        orders[orderId].whoOrders = msg.sender;
        orders[orderId].status = OrderStatus.AVAILABLE_FOR_SALE;
        orders[orderId].overallStatus = "Order Requested";
        orders[orderId].durationOfOrderCreation = block.timestamp;

        emit Events.OrderRequested(
            msg.sender,
            msg.value,
            orderId,
            batchId,
            quantity
        );
        return orderId;
    }

    function approveOrder(uint256 _orderId) external {
        require(orders[_orderId].whoOrders != address(0), "Invalid order ID");
        UserRoleManager.userRole approverRole = userRoleManager.getUserRole(
            msg.sender
        );

        require(
            approverRole == UserRoleManager.userRole.Manufacturer ||
                approverRole == UserRoleManager.userRole.Retailer,
            "Only Manufacturer or Retailer can approve orders"
        );

        UserRoleManager.userRole orderOriginatorRole = userRoleManager
            .getUserRole(orders[_orderId].whoOrders);

        if (orderOriginatorRole == UserRoleManager.userRole.Consumers) {
            require(
                approverRole == UserRoleManager.userRole.Retailer,
                "Only a Retailer can approve consumer orders"
            );
        } else if (orderOriginatorRole == UserRoleManager.userRole.Retailer) {
            require(
                approverRole == UserRoleManager.userRole.Manufacturer,
                "Only a Manufacturer can approve retailer orders"
            );
        } else {
            revert("Order cannot be approved by this role");
        }

        orders[_orderId].status = OrderStatus.ORDER_APPROVED;
        orders[_orderId].overallStatus = "Order Approved";

        emit Events.OrderApproved(
            _orderId,
            msg.sender,
            orders[_orderId].whoOrders,
            "Order Approved"
        );
    }
}
