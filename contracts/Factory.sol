//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Crowdfunding.sol";

contract Factory {
    
    mapping(address => uint256) public balances;

    mapping(address => address[]) public userCrowdfundings;
    address[] public crowdfundingContracts;

    address public template;

    constructor() {
        template = address(new Crowdfunding());
    }

    function importToken(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        balances[msg.sender] += amount;
    }

    function createCrowdfunding(string memory description, uint256 meta) external {
        address clone = Clones.clone(template);
        Crowdfunding(clone).initialize(msg.sender, description, meta);

        crowdfundingContracts.push(clone);
        userCrowdfundings[msg.sender].push(clone);
    }

    function donate(uint256 amount, address crowdfunding) external {
        require(amount > 0, "Amount must be greater than zero");
        require(balances[msg.sender] >= amount, "Insufficient token balance");
        
        balances[msg.sender] -= amount;
        Crowdfunding(crowdfunding).receiveDonation(msg.sender, amount);
    }

    function refunds(address crowdfunding) external {
        (address[] memory refundedDonors, uint256[] memory amounts) = Crowdfunding(crowdfunding).prepareRefunds(msg.sender);

        for (uint256 i = 0; i < refundedDonors.length; i++) {
            if (amounts[i] > 0) {
                balances[refundedDonors[i]] += amounts[i];
            }
        }
    }

    function claimFunds(address crowdfunding) external {
        uint256 amount = Crowdfunding(crowdfunding).withdrawToFactory(msg.sender);
        balances[msg.sender] += amount;
    }
}