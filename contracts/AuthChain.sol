// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "./lib/error.sol";

contract AuthChain {

    // user roles to manage access controls
    enum userRole { Consumers, Manufacturer, Distributors, Retailers, Admin }

    /**
     * using different structs to manage details 
     * for different types of users on the platform
     */
    struct Manufacturer {
        string brandName;
        bool verify;
        string nafdac_no;
        string registration_no;
        userRole role;
    }

    struct Distributor {
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
    mapping (address => Distributor) distributor;
    mapping (address => Retailer) retailer;
    mapping (address => Consumer) consumer;
    mapping(address => Admin) admin;

    // private functions for access control

    function onlyManfacturer() private view {
        if(uint(manufacturer[msg.sender].role) != 1) {
            revert Errors.NotAManufacturer();
        }
    }

    function onlyAdmin() private view {
        if(uint(admin[msg.sender].role) != 4) {
            revert Errors.NotAnAdmin();
        }
    }


    // setters functions
    function registerManufacturer(
        string memory _brandName,
        string memory _nafdac_no,
        string memory _registration_no
    ) external {
        Manufacturer memory manufacturerData = Manufacturer({
            brandName: _brandName,
            verify: false,
            nafdac_no: _nafdac_no,
            registration_no: _registration_no,
            role: userRole.Manufacturer
        });

        manufacturer[msg.sender] = manufacturerData;
    }

    function registerDistributor(
        uint256 _uid,
        string memory _brandName
    ) external {
        onlyManfacturer();
        Distributor memory distributorData = Distributor({
            uid: _uid,
            brandName: _brandName,
            active: true,
            role: userRole.Distributors
        });

        distributor[msg.sender] = distributorData;
    }

    function registerRetailer(
        string memory _brandName
    ) external {
        Retailer memory retailerData = Retailer({
            brandName: _brandName,
            role: userRole.Retailers
        });

        retailer[msg.sender] = retailerData;
    }

    function registerConsumer() external {
        Consumer memory consumerData = Consumer({
            role: userRole.Consumers
        });

        consumer[msg.sender] = consumerData;
    }

    function registerAdmin() external {
        Admin memory adminData = Admin({
            role: userRole.Admin
        });

        admin[msg.sender] = adminData;
    }

    function verifyManufacturer(
        address manufacturerAddress
    ) external {
        onlyAdmin();
        manufacturer[manufacturerAddress].verify = true;
    }


    // getters functions

    function getManufacturer() external view returns(Manufacturer memory manufacturerDetails) {
        manufacturerDetails = manufacturer[msg.sender];
    }

    function getRetailer() external view returns(Distributor memory distributorDetails) {
        distributorDetails = distributor[msg.sender];
    }

    function getDistributor() external view returns(Retailer memory retailerDetails) {
        retailerDetails = retailer[msg.sender];
    }
    

    function getConsumer() external view returns(Consumer memory consumerDetails) {
        consumerDetails = consumer[msg.sender];
    }

    function getAdmin() external view returns(Admin memory adminDetails) {
        adminDetails = admin[msg.sender];
    }
}