// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

library Events {
    
    // Events
    event ManufacturerRegistered(
        address indexed manufacturerAddress,
        string brandName,
        string nafdac_no,
        uint256 yearOfRegistration
    );

    event RetailerRegistered(
        address indexed retailerAddress,
        string brandName
    );

    event ConsumerRegistered(
        address indexed consumerAddress
    );

    event AdminRegistered(
        address indexed adminAddress
    );

    event ManufacturerVerified(
        address indexed manufacturerAddress
    );

    

    event ProductAdded(
        uint256 indexed productCode,
        string productName,
        uint256 quantity,
        address indexed manufacturer
    );

    event ProductToRetailer(
        uint256 indexed productCode,
        address indexed retailer,
        uint256 quantity
    );

    event ProductSoldToConsumer(
        uint256 indexed productCode,
        address indexed consumer,
        uint256 quantity
    );

}