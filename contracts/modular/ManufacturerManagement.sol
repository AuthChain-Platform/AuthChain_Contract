// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import "./ProductManagement.sol";
import "./UserRoleManager.sol";

contract ManufacturerManagement {

    uint256 id;
    
    address public owner;
    ProductManagement productManagement;
    UserRoleManager userRoleManager;

    constructor(address _productManagementAddress, address _userRoleManagerAddress) {
        owner = msg.sender;
        productManagement = ProductManagement(_productManagementAddress);
        userRoleManager = UserRoleManager(_userRoleManagerAddress);
    }

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
    
    struct Product {
        uint256 productCode;
        string name;
        uint256 price;
        uint256 batchID;
        string productDescription;
        uint256 quantity;
        uint256 availableQuantity;
        string productImage;
        bool status;
        address manufacturer;  // Track owner of the product
        bool available;
        uint256 productionDate;
        uint256 expiryDate;
    }

    mapping(uint256 => Product) public products;
    
    uint256[] public productList;

    mapping(address => Manufacturer) public manufacturers;
    // tracks manufacturer to batchId to productCode
    mapping(address => mapping(uint => string[])) public identifier;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedManufacturer(address manufacturerAddress) {
        require(manufacturers[manufacturerAddress].verify == true, "Only verified manufacturers can perform this action");
        _;
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

    function createProductCode(uint256 _id) internal returns (string memory batchId) {
        return string(abi.encodePacked("authChain_", Strings.toString(_id)));
    }

    uint256 productCreatedCountid; //uique productCountet id

    function createProduct(
        string memory _productName,
        uint256 _expiryDate,
        uint256 _quantity,
        uint256 _productionDate,
        string memory _productImage
    ) public onlyVerifiedManufacturer(msg.sender) returns(uint256 batchId, string[] memory productIds) {

        uint256 _batchId = productManagement.createProduct(_productName, _expiryDate, "", _quantity, _productionDate, _productImage);
    
        productIds = new uint256[](_quantity);
        for (uint256 loopThrough = 0; loopThrough < _quantity;  loopThrough++){
            productIds[loopThrough] = _productName + brandName + loopThrough;
        } 
        return (batchId, productIds);
    }

    function listProduct(uint256 _batchId, uint256 _price,
    uint256 _quantity) public {
        require(manufacturers[msg.sender].verify == true, "Only verified manufacturers can list products");
        productManagement.listProductToMarket(_batchId, _price, quantity);
    }








//  listProdcuts


    // Add product to manufacturer
    // function createProduct(
    //     address manufacturerAddress,
    //     string memory name,
    //     uint256 price,
    //     uint256 batchID,
    //     string memory expiryDate,
    //     string memory productDescription,
    //     uint256 quantity,
    //     string memory productImage

    // ) public onlyVerifiedManufacturer(manufacturerAddress) {
    //     Manufacturer storage manufacturer = manufacturers[manufacturerAddress];
    //     productManagement.createProduct(
    //         name,
    //         price,
    //         batchID,
    //         expiryDate,
    //         productDescription,
    //         quantity,
    //         productImage
    //     );
        
    //     // Add the product code to the manufacturer's list of product codes
    //     manufacturer.productCodes[manufacturer.totalProducts] = productCode;
    //     manufacturer.totalProducts++;
    // }
}
