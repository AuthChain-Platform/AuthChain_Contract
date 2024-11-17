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
        //reatiler can order, customer can order
      address whoOrders;
      // array of Items in Order
      OrderItem[] items;
      OrderStatus status;
      string overallStatus;
      uint256 durationOfOrderCreation;
    }

    mapping(uint256 => Order) public orders;

    function requestOrder(
        uint256 _batchId,
        uint256 _quantity
    ) external payable returns(uint256 orderId) {
        require(_quantity > 0, "Quantity  Must be greater than 0");

        orderId = uint256(
            keccak256(abi.encodePacked(msg.sender, batchId, block.timestamp))
        );
        orders[orderId].whoOrders = msg.sender;
        orders[orderId].status = OrderStatus.AVAILABLE_FOR_SALE;
        orders[orderId].overallStatus = "Order Requested";
        orders[orderId].durationOfOrderCreation = block.timestamp;

        emit Events.OrderRequested(msg.sender, msg.value, orderId, batchId, quantity);
        return orderId;
    }

    function approveOrder(uint256 _orderId, address _retailer) external {
       UserRoleManager.userRole role = userRoleManager.getUserRole(msg.sender);
        require(
            role == UserRoleManager.userRole.Manufacturer || role == UserRoleManager.userRole.Admin,
            "Only Manufacturer or Admin can approve orders"
        );

        require(orders[_orderId].whoOrders == _retailer, "This order is not placed by the retailer");

        orders[_orderId].status = OrderStatus.ORDER_APPROVED;
        orders[_orderId].overallStatus = "Order Approved";

        emit OrderApproved(_orderId, msg.sender, _retailer, "Order Approved");

    }
}
