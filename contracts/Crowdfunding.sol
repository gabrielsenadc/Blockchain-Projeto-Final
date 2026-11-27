//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract Crowdfunding is Initializable {

    address public owner;
    address public factoryAddress;

    mapping(address => uint256) public donations;
    mapping(address => bool) private hasDonated;
    address[] public donors;
    uint256 public totalRaised;

    bool public claimed;
    bool public active;
    uint256 public meta;
    string public description;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, string memory _description, uint256 _meta) external initializer {
        factoryAddress = msg.sender;
        owner = _owner;
        description = _description;
        meta = _meta;
        active = true;
        claimed = false;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    modifier onlyFactory {
        require(msg.sender == factoryAddress, "You are not the factory");
        _;
    }

    modifier notClaimed {
        require(!claimed, "Funds already claimed");
        _;
    }

    modifier isActive {
        require(active, "Crowdfunding is not active");
        _;
    }

    function receiveDonation(address userAddress, uint256 amount) external onlyFactory isActive {
        require(amount > 0, "Donation amount must be greater than zero");

        if (!hasDonated[userAddress]) {
            hasDonated[userAddress] = true;
            donors.push(userAddress);
        }

        donations[userAddress] += amount;
        totalRaised += amount;
    }

    function prepareRefunds(address caller) external onlyFactory notClaimed isActive 
    returns (address[] memory refundedDonors, uint256[] memory amounts) {
        require(caller == owner, "You are not the owner");

        active = false;

        uint256 count = donors.length;
        refundedDonors = new address[](count);
        amounts = new uint256[](count);

        for (uint256 i = 0; i < count; i++) {
            address donor = donors[i];
            uint256 amount = donations[donor];

            refundedDonors[i] = donor;
            amounts[i] = amount;

            if (amount > 0) {
                donations[donor] = 0;
                totalRaised -= amount;
            }
        }
    }

    function withdrawToFactory(address caller) external onlyFactory notClaimed  returns (uint256 amount) {
        require(caller == owner, "Voce nao eh o dono");
        require(totalRaised > 0, "Nothing to withdraw");

        amount = totalRaised;
        claimed = true;
        active = false;
    }

    function deactivate() external onlyOwner isActive{
        active = false;
    }

    function activate() external onlyOwner {
        active = true;
    }

}
