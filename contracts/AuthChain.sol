// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./lib/error.sol";

contract AuthChain {
    address adminUser;
    constructor() {
        adminUser = msg.sender;
    }

    // user roles to manage access controls
    enum userRole { Default, Consumers, Manufacturer, LogisticsPersonnel, Retailers, Admin }

    /**
     * using different structs to manage details 
     * for different types of users on the platform
     */
    struct Manufacturer {
        string brandName;
        bool verify;
        string nafdac_no;
        string registration_no;
        uint256 yearOfRegistration;
        userRole role;
    }

    struct LogisticsPersonnel {
        uint256 uid;
        string brandName;
        bool active;
        userRole role;
    }

    struct Retailer {
        string brandName;
        userRole role;
    }

    struct Consumer {
        userRole role;
    }

    struct Admin {
        userRole role;
    }


    //mapping to retrieve users
    mapping (address => Manufacturer) manufacturer;
    mapping (address => LogisticsPersonnel) logisticsPersonnel;
    mapping (address => Retailer) retailer;
    mapping (address => Consumer) consumer;
    mapping(address => Admin) admin;

    // private functions for access control

    function onlyManfacturer() private view {
        if(uint(manufacturer[msg.sender].role) != 2) {
            revert Errors.NotAManufacturer();
        }
    }

    function onlyAdmin() private view {
        if(uint(admin[msg.sender].role) != 5) {
            revert Errors.NotAnAdmin();
        }
    }

    function onlyadminUser() private view {
        if(msg.sender == adminUser) {
            revert Errors.NotAnAdminUser();
        }
    }


    // setters functions
    function registerManufacturer(
        string memory _brandName,
        string memory _nafdac_no,
        string memory _registration_no,
        uint256 _yearOfRegistration
    ) external {
        Manufacturer memory manufacturerData = Manufacturer({
            brandName: _brandName,
            verify: false,
            nafdac_no: _nafdac_no,
            registration_no: _registration_no,
            yearOfRegistration: _yearOfRegistration,
            role: userRole.Default
        });

        manufacturer[msg.sender] = manufacturerData;
    }

    function registerDistributor(
        uint256 _uid,
        string memory _brandName
    ) external {
        onlyManfacturer();
        LogisticsPersonnel memory logisticsPersonnelData = LogisticsPersonnel({
            uid: _uid,
            brandName: _brandName,
            active: true,
            role: userRole.Default
        });

        logisticsPersonnel[msg.sender] = logisticsPersonnelData;
    }

    function registerRetailer(
        string memory _brandName
    ) external {
        Retailer memory retailerData = Retailer({
            brandName: _brandName,
            role: userRole.Default
        });

        retailer[msg.sender] = retailerData;
    }

    function registerConsumer() external {
        Consumer memory consumerData = Consumer({
            role: userRole.Default
        });

        consumer[msg.sender] = consumerData;
    }

    function registerAdmin() external {
        Admin memory adminData = Admin({
            role: userRole.Default
        });

        admin[msg.sender] = adminData;
    }

    function verifyManufacturer(
        address manufacturerAddress
    ) external {
        onlyAdmin();
        manufacturer[manufacturerAddress].verify = true;
    }


    function assignAdmin(address adminAddress) external {
        onlyadminUser();
        admin[adminAddress].role = userRole.Admin;
    }


    // handles assigning user roles
    function assignUserRoles(address userAddress, userRole role) external {
        onlyAdmin();
        if(uint(role) == 2) {
            manufacturer[userAddress].role = userRole.Manufacturer;
        }

        if(uint(role) == 3) {
            manufacturer[userAddress].role = userRole.LogisticsPersonnel;
        }

        if(uint(role) == 1) {
            manufacturer[userAddress].role = userRole.Consumers;
        }

        if(uint(role) == 4) {
            manufacturer[userAddress].role = userRole.Retailers;
        }

        
    }

    // getters functions

    function getManufacturer() external view returns(Manufacturer memory manufacturerDetails) {
        manufacturerDetails = manufacturer[msg.sender];
    }

    function getLogisticsPersonnel() external view returns(LogisticsPersonnel memory LogisticsPersonnelDetails) {
        LogisticsPersonnelDetails = logisticsPersonnel[msg.sender];
    }

    function getRetailer() external view returns(Retailer memory retailerDetails) {
        retailerDetails = retailer[msg.sender];
    }
    

    function getConsumer() external view returns(Consumer memory consumerDetails) {
        consumerDetails = consumer[msg.sender];
    }

    function getAdmin() external view returns(Admin memory adminDetails) {
        adminDetails = admin[msg.sender];
    }
}