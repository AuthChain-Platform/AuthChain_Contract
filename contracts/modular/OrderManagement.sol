// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

contract OrderManagement {
  // in situation where users are ordering for items
  // of different batches.
  struct OrderItem {
    uint256 batchId;
    uint256 quantity;
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
    OrderItem[] totalCost;
    OrderStatus status;
    string overallStatus;

  }


}