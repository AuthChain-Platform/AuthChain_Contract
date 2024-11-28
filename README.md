# Authentic Chain

THis is blockchain-based product authentication system that addresses the growing issue of counterfeiting and ensure the authenticity of products. It enables businesses and consumers to track products through the entire supply chain, from manufacturing to retail, ensuring transparency, security, and trust. Consumers can easily verify the authenticity of their ordered items reducing the impact of counterfeit goods.

## Overview

This project consists of a set of smart contracts that manage the relationships between **retailers**, **distributors**, and **manufacturers** in a decentralized supply chain system. The system allows for registration, role assignment, product ordering, and inventory management, enabling verified retailers and distributors to interact with each other and with manufacturers for product orders and inventory updates.

### Key Features:
- **Distributor Management**: Register, view, and manage distributors, including product orders and verification.
- **Retailer Management**: Register, verify, and manage retailers, handle product orders from distributors and manufacturers, and manage retailer inventories.
- **User Role Management**: Assign different roles (Retailer, Distributor, Staff) using a separate contract for role-based access control.
- **Product Management**: Manage products, including tracking available quantities, ownership transfers, and purchasing

## Prerequisites

To interact with these smart contracts, you need:

- **Solidity 0.8.27** or higher.
- **Hardhat** development environment
- **Metamask** or any Ethereum wallet for interacting with the contracts.
- **Node.js** for managing project dependencies.


## Installation

1. **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd <project_directory>
    ```

2. **Install dependencies:**
    Use your preferred package manager, for example:
    ```bash
    npm install
    ```

3. **Compile the contracts:**
    ```bash
    npx hardhat compile
    ```

---

## Contract Overview

### `UserRoleManager Contract`
This contract manages the roles of users (e.g., Distributor, Retailer, Staff). It assigns and verifies roles, ensuring that only authorized users can perform specific actions.

### `ProductManagement Contract`
This contract manages products, including adding new products, getting product details, and transferring product ownership. It tracks product quantity and availability for both distributors and retailers.

### `DistributorManagement Contract`
This contract handles the registration and management of distributors. Verified distributors can purchase products from manufacturers and manage their inventory. The contract also supports events related to product purchases and distribution.

### `RetailerManagement Contract`
This contract handles the registration and management of retailers. Retailers can order products from distributors or directly from manufacturers. Retailers also maintain an inventory of products and can assign staff to their stores.

---

## Usage

### Registering a Retailer

To register a new retailer, call the `registerRetailer` function with the following parameters:
- `retailerName`: Name of the retailer.
- `registration_no`: Registration number of the retailer.
- `yearOfRegistration`: Year of registration.
- `location`: Location of the retailer.
- `state`: State of the retailer.
- `image`: Image URL for the retailer.

### Ordering Products from a Distributor

Retailers can order products from distributors using the `orderProductByRetailer` function. The retailer will specify:
- `productId`: The ID of the product to be ordered.
- `quantity`: The quantity of the product to be ordered.

### Ordering Products from a Manufacturer

Retailers can directly order products from manufacturers using the `orderProductFromManufacturer` function. This function is restricted to verified retailers. It requires:
- `productId`: The ID of the product to be ordered.
- `quantity`: The quantity of the product to be ordered.

---

# Contract Addresses

1. UserRoleManager: 0x65f34d19a3B47c0177661C32497470543816C40c
   https://sepolia-blockscout.lisk.com/address/0x65f34d19a3B47c0177661C32497470543816C40c#code

2. ProductManagement: 0x3D8ceA276f85Dd8b373f2Db22Ac3b4A870cF15ae
   https://sepolia-blockscout.lisk.com/address/0x4456ce0eBadB36Ad298Ff19ce4aC18075c4407Cb#code

3. DistributorManagement: 0x00fCCefe9eD0B3Fb38a8D1B668302ce194e0b58C
   https://sepolia-blockscout.lisk.com/address/0x7946a63a691555eA75736cDEd41d036C63734881#code

4. RetailerManagement: 0x757067EA4CF3b6DB4eB0FC4ea9efb715B515d289
5. https://sepolia-blockscout.lisk.com/address/0x83FeD617C5646F04c13169F58911fa657001FeDE#code

6. ConsumerManagement: 0xCCc879D2dF9eaAF6A6103CF67451218016F39a7d


---

## License

This project is licensed under the MIT License.
