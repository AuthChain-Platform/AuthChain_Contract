// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./UserRoleManager.sol";
import "./ProductManagement.sol";
import "./DistributorManagement.sol";



contract RetailerManagement {

    address public owner;
    UserRoleManager public userRoleManager;
    ProductManagement public productManagement;
    DistributorManagement public distributorManagement;

    struct Retailer {
        uint256 id;
        string retailerName;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        string state;
        string image;
        bool verified;
         uint256[] productIds; // List of product IDs
        mapping(uint256 => uint256) inventory; // productId => quantity

    }

    mapping(address => Retailer) public retailers;
    mapping(address => UserRoleManager.userRole) public retailerRoles;
    mapping(address => mapping(uint256 => uint256)) public retailerInventory;
    address[] public allRetailers;

    event RetailerRegistered(
        address indexed retailerAddress,
        uint256 id,
        string retailerName,
        string registration_no,
        uint256 yearOfRegistration,
        string location,
        string state,
        string image
    );

    event ProductOrderedFromDistributor(
        uint256 productId,
        address indexed retailer,
        uint256 quantity,
        uint256 retailerInventory
    );

     event ProductOrderedFromManufacturer(
        uint256 indexed productId,
        address indexed retailer,
        uint256 quantity,
        uint256 newAvailableQuantity,
        uint256 trackingId
    );



    event StaffAdded(address indexed retailer, address indexed staff);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyVerifiedRetailer() {
        require(retailers[msg.sender].verified, "You must be a verified retailer.");
        _;
    }

    constructor(
        address _userRoleManagerAddress,
        address _productManagementAddress,
        address _distributorManagementAddress
    ) {
        require(_userRoleManagerAddress != address(0), "Invalid UserRoleManager address");
        require(_productManagementAddress != address(0), "Invalid ProductManagement address");
        require(_distributorManagementAddress != address(0), "Invalid DistributorManagement address");

        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManagerAddress);
        productManagement = ProductManagement(_productManagementAddress);
        distributorManagement = DistributorManagement(_distributorManagementAddress);
    }

    function registerRetailer(
        string memory retailerName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image

    ) public
     {
        require(bytes(retailerName).length > 0, "Retailer name is required");
        require(bytes(location).length > 0, "Location is required");
        require(bytes(registration_no).length > 0, "Registration number is required");
        require(yearOfRegistration > 0, "Year of registration is required");
        require(bytes(state).length > 0, "State is required");

        Retailer storage retailer = retailers[msg.sender];
        
        require(!retailer.verified, "Retailer already registered");
        require(retailers[msg.sender].id == 0, "Retailer is already registered");


        retailer.id = allRetailers.length + 1;
        retailer.retailerName = retailerName;
        retailer.registration_no = registration_no;
        retailer.yearOfRegistration = yearOfRegistration;
        retailer.location = location;
        retailer.state = state;
        retailer.image = image;
        retailer.verified = true;

        allRetailers.push(msg.sender);

        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Retailers);

        emit RetailerRegistered(
            msg.sender,
            retailer.id,
            retailerName,
            registration_no,
            yearOfRegistration,
            location,
            state,
            image
        );
    }


    function viewDistributorID() public view returns (uint256) {
        return distributorManagement.viewdistributorID();
    }


    function orderProductByRetailer(uint256 productId, uint256 quantity) public {
        distributorManagement.orderProductFromDistributor(productId, quantity);

        emit ProductOrderedFromDistributor(productId, msg.sender, quantity, retailerInventory[msg.sender][productId]);

    }


    function orderProductFromManufacturer(
        uint256 productId,
        uint256 quantity
    ) public onlyVerifiedRetailer {
        require(quantity > 0, "Quantity must be greater than zero");

        (
            ,
            ,
            ,
            ,
            ,
            uint256 availableQuantity,
            ,
            ,
           ,
            uint256 trackingId
        ) = productManagement.getProductDetails(productId);


        require(availableQuantity >= quantity, "Insufficient manufacturer stock");

        uint256 newAvailableQuantity = availableQuantity - quantity;

        Retailer storage retailer = retailers[msg.sender];
        if (retailer.inventory[productId] == 0) {
            retailer.productIds.push(productId); 
        }
        retailer.inventory[productId] += quantity;

        emit ProductOrderedFromManufacturer(
            productId,
            msg.sender,
            quantity,
            newAvailableQuantity,
            trackingId
        );
    }

    function getRetailerProducts() public view onlyVerifiedRetailer returns (uint256[] memory productIds, uint256[] memory quantities) {
        Retailer storage retailer = retailers[msg.sender];
        uint256 length = retailer.productIds.length;

        productIds = new uint256[](length);
        quantities = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            uint256 productId = retailer.productIds[i];
            productIds[i] = productId;
            quantities[i] = retailer.inventory[productId];
        }
    }

    
    function addStaff(address staffAddress) external onlyVerifiedRetailer {
        require(staffAddress != address(0), "Invalid staff address");

        userRoleManager.assignRole(staffAddress, UserRoleManager.userRole.Staff);
        emit StaffAdded(msg.sender, staffAddress);
    }

    function checkRetailersProductLists() public view returns (uint256[] memory productIds, uint256[] memory quantities) {
        uint256 inventorySize = allRetailers.length + 1;
        uint256[] memory ids = new uint256[](inventorySize);
        uint256[] memory qtys = new uint256[](inventorySize);

        for (uint256 i = 0; i < inventorySize; i++) {
            ids[i] = i + 1;
            qtys[i] = retailerInventory[msg.sender][i + 1];
        }

        return (ids, qtys);
    }

    function getRetailerDetails() 
        public 
        view 
        returns (
            string memory retailerName,
            string memory registration_no,
            uint256 yearOfRegistration,
            string memory location,
            string memory state,
            string memory image,
            bool verified
        ) 
    {
        Retailer storage retailer = retailers[msg.sender];
        return (
            retailer.retailerName,
            retailer.registration_no,
            retailer.yearOfRegistration,
            retailer.location,
            retailer.state,
            retailer.image,
            retailer.verified
        );
    }

    function viewAllRetailers() public view returns (address[] memory) {
        return allRetailers;
    }
}
