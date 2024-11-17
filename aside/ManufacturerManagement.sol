// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./ProductManagement.sol";
import "./UserRoleManager.sol";

contract ManufacturerManagement {

    uint256 id;
    
    address public owner;
    ProductManagement public productManagement;
    UserRoleManager public userRoleManager;

    struct Manufacturer {
        string brandName;
        bool verify;
        string nafdac_no;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        uint256 totalProducts;
        mapping(uint256 => uint256) productCodes;
    }

    mapping(address => Manufacturer) public manufacturers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedManufacturer(address manufacturerAddress) {
        require(manufacturers[manufacturerAddress].verify == true, "Only verified manufacturers can perform this action");
        _;
    }

    constructor(address _productManagementAddress, address _userRoleManagerAddress) {
        owner = msg.sender;
        productManagement = ProductManagement(_productManagementAddress);
        userRoleManager = UserRoleManager(_userRoleManagerAddress);
    }

    // Register a new manufacturer
    function registerManufacturer(

        address manufacturerAddress,
        string memory brandName,
        string memory nafdac_no,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location

    ) public onlyOwner {

//        uint256 newManufacturerId = id + 1;

        Manufacturer storage newManufacturer = manufacturers[msg.sender];
        
        newManufacturer.brandName = brandName;
        newManufacturer.verify = true;
        newManufacturer.nafdac_no = nafdac_no;
        newManufacturer.registration_no = registration_no;
        newManufacturer.yearOfRegistration = yearOfRegistration;
        newManufacturer.location = location;
        newManufacturer.totalProducts = 0;
        
        // Assigning Manufacturer role to the user when they register
        userRoleManager.assignRole(manufacturerAddress, UserRoleManager.userRole.Manufacturer);
    }

    // Deregister a manufacturer
    function deregisterManufacturer(address manufacturerAddress) public onlyOwner {
        delete manufacturers[manufacturerAddress];
    }

    // Update manufacturer information
    function updateManufacturerInfo(
        address manufacturerAddress,
        string memory brandName,
        string memory nafdac_no,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location
    ) public onlyOwner {
        Manufacturer storage manufacturer = manufacturers[manufacturerAddress];
        require(manufacturer.verify, "Manufacturer must be registered and verified");
        manufacturer.brandName = brandName;
        manufacturer.nafdac_no = nafdac_no;
        manufacturer.registration_no = registration_no;
        manufacturer.yearOfRegistration = yearOfRegistration;
        manufacturer.location = location;
    }

    // Add product to manufacturer
    function addProduct(
        address manufacturerAddress,
        uint256 productCode,
        string memory name,
        uint256 price,
        uint256 batchID,
        string memory expiryDate,
        string memory productDescription,
        uint256 quantity,
        string memory productImage

    ) public onlyVerifiedManufacturer(manufacturerAddress) {
        Manufacturer storage manufacturer = manufacturers[manufacturerAddress];

        productManagement.addProduct(
            productCode,
            name,
            price,
            batchID,
            expiryDate,
            productDescription,
            quantity,
            productImage
        );
        
        // Add the product code to the manufacturer's list of product codes
        manufacturer.productCodes[manufacturer.totalProducts] = productCode;
        manufacturer.totalProducts++;
    }
}
