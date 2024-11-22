// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "./ProductManagement.sol";
import "./UserRoleManager.sol";

contract DistributorManagement {

    uint256 public id;
    address public owner;
    UserRoleManager public userRoleManager;
    ProductManagement public productManagement;

    struct Distributor {
        uint256 id;
        address distributorAddress;
        string distributorName;
        string registration_no;
        uint256 yearOfRegistration;
        string location;
        string state;
        string image;
        bool verified;
        uint256 totalDistributions;
        uint256 totalSales;
        uint256 totalProducts;
    }

    Distributor[] public allDistributors;
    mapping(address => UserRoleManager.userRole) public distributorRoles;
    mapping(address => uint256) public distributorIdMap;
    mapping(address => uint256[]) public distributorProducts;

    mapping(address => mapping(uint256 => uint256)) public distributorProductQuantities;


    event ProductPurchased(uint256 indexed productId, address indexed buyer, uint256 quantity, uint256 indexed newAvailableQuantity, uint256 trackingId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    modifier onlyVerifiedDistributor() {
        bool isVerified = false;
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].distributorAddress == msg.sender && allDistributors[i].verified) {
                isVerified = true;
                break;
            }
        }
        require(isVerified, "Only verified distributor can perform this action");
        _;
    }

    constructor(address _userRoleManager, address _productManagementAddress) {
        owner = msg.sender;
        userRoleManager = UserRoleManager(_userRoleManager);
        productManagement = ProductManagement(_productManagementAddress);
    }

    function registerDistributor(
        string memory distributorName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public {
        for (uint i = 0; i < allDistributors.length; i++) {
            require(allDistributors[i].distributorAddress != msg.sender, "Distributor already registered");
        }

        uint256 newDistributorId = id + 1;
        id = newDistributorId;

        allDistributors.push(Distributor({
            id: newDistributorId,
            distributorAddress: msg.sender,
            distributorName: distributorName,
            registration_no: registration_no,
            yearOfRegistration: yearOfRegistration,
            location: location,
            state: state,
            image: image,
            verified: true,
            totalDistributions: 0,
            totalSales: 0,
            totalProducts: 0
        }));

        distributorRoles[msg.sender] = UserRoleManager.userRole.Distributor;
        distributorIdMap[msg.sender] = newDistributorId;
        userRoleManager.assignRole(msg.sender, UserRoleManager.userRole.Distributor);
    }
    
    function deregisterDistributor(uint256 distributorId) public onlyOwner {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                allDistributors[i] = allDistributors[allDistributors.length - 1];
                allDistributors.pop();
                break;
            }
        }
    }

    function updateDistributorInfo(
        uint256 distributorId,
        string memory distributorName,
        string memory registration_no,
        uint256 yearOfRegistration,
        string memory location,
        string memory state,
        string memory image
    ) public onlyOwner {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                allDistributors[i].distributorName = distributorName;
                allDistributors[i].registration_no = registration_no;
                allDistributors[i].yearOfRegistration = yearOfRegistration;
                allDistributors[i].location = location;
                allDistributors[i].state = state;
                allDistributors[i].image = image;
                break;
            }
        }
    }

    function viewAllRegisteredDistributors() public view returns (Distributor[] memory) {
        return allDistributors;
    }

    function viewPurchasedProductQuantities(uint256 distributorId) public view returns (uint256[] memory, uint256[] memory) {
        
        uint256[] memory productIds = new uint256[](allDistributors.length);
        uint256[] memory quantities = new uint256[](allDistributors.length);

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                productIds[0] = allDistributors[i].totalProducts;
                quantities[0] = allDistributors[i].totalDistributions;
                break;
            }
        }
        return (productIds, quantities);
    }
    
    function checkDistributorRole(address distributorAddress) public view returns (string memory) {
        if (distributorRoles[distributorAddress] == UserRoleManager.userRole.Distributor) {
            return "Distributor";
        }
        return "No Role";
    }


    function orderProductFromDistributor(uint256 productId, uint256 quantity) public {
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
            address currentOwner, 
            uint256 trackingId
        ) = productManagement.getProductDetails(productId);

        require(availableQuantity >= quantity, "Insufficient stock");
        require(currentOwner != address(0), "Product not available for sale");

        uint256 newAvailableQuantity = availableQuantity - quantity;

        productManagement.transferProductOwnership(productId, msg.sender);

        Distributor storage distributor = allDistributors[distributorIdMap[msg.sender] - 1];
        distributor.totalProducts += quantity;
        distributor.totalDistributions += 1; 
        distributorProducts[msg.sender].push(productId);

        emit ProductPurchased(productId, msg.sender, quantity, newAvailableQuantity, trackingId);
    }


    function viewDistributorProducts() public view returns (uint256[] memory productIds, uint256[] memory quantities) {
        require(msg.sender != address(0), "Invalid distributor address");

        uint256[] memory productIds = distributorProducts[msg.sender];
        uint256[] memory quantities = new uint256[](productIds.length);

        for (uint i = 0; i < productIds.length; i++) {
            quantities[i] = distributorProductQuantities[msg.sender][productIds[i]]; // Track quantities
        }

        return (productIds, quantities);
    }

    function buy(uint256 productId, uint256 quantity) public payable onlyVerifiedDistributor {
        require(quantity > 0, "Quantity must be greater than zero");

        ( , uint256 price, , , , uint256 availableQuantity, , , ,) = productManagement.getProductDetails(productId);


        require(availableQuantity >= quantity, "Insufficient stock");

        uint256 totalPrice = price * quantity;
        
        require(msg.value >= totalPrice, "Insufficient funds");

        uint256 trackingId = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, productId, quantity)));

        productManagement.purchaseProduct{value: totalPrice}(productId, quantity);

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].distributorAddress == msg.sender) {
                allDistributors[i].totalProducts -= quantity;  
                allDistributors[i].totalSales += totalPrice; 
                break;
            }
        }


        payable(msg.sender).transfer(totalPrice);


        emit ProductPurchased(productId, msg.sender, quantity, totalPrice, trackingId);

        uint256 refund = msg.value - totalPrice;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }


    function viewDistributorRevenue(uint256 distributorId) public view returns (uint256) {
        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                return allDistributors[i].totalSales; 
            }
        }
        revert("Distributor not found");
    }


    function viewDistributorProducts(uint256 distributorId) public view returns (uint256[] memory, uint256[] memory) {
        uint256[] memory productIds = new uint256[](allDistributors.length);
        uint256[] memory productQuantities = new uint256[](allDistributors.length);
        uint256 index = 0;

        for (uint i = 0; i < allDistributors.length; i++) {
            if (allDistributors[i].id == distributorId) {
                productIds[index] = distributorId; 
                productQuantities[index] = allDistributors[i].totalProducts;
                index++;
            }
        }

        return (productIds, productQuantities);
    }

    function showAllDistributors() public view returns (Distributor[] memory) {
        return allDistributors;
    }


    function getDistributorProducts() public view returns (uint256[] memory) {
        return distributorProducts[msg.sender];
    }

}
