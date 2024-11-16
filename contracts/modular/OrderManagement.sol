// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract OrderManagement {
  // in situation where users are ordering for items
  // of different batches.
  struct OrderItem {
    uint256 batchId;
    uint256 quantity;
  }

  struct OrderStatus {
    
  }

  struct Order {
    //reatiler can order, customer can order
    address whoOrders; 
    // array of Items in Order
    OrderItem[] totalCost;
    OrderStatus status;
  }


}