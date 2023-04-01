// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// import "./interfaces/IStakingManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "hardhat/console.sol";

contract OrganizationVault is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Organization {
        string id;
        address[] owners;
        uint256 approval_threshold;
        uint256 balance;
    }

    struct Project {
        string id;
        string organizationId;
    }

    struct Movement {
        string id;
        uint256 amount;
        address payTo;
        address proposedBy;
    }

    mapping(bytes32 => Organization) public organizations;
    EnumerableSet.Bytes32Set private organizationHashIds;

    // Organization[] public organizations;
    Project[] public projects;
    Movement[] public movements;

    address public immutable baseToken;
    
    constructor(address _baseToken) {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }

    function createOrganization(
        string memory _id,
        address[] memory _owners,
        // address _owners,
        uint256 _approval_threshold
    ) external onlyOwner {
        // TODO: require the _id to exist in Cedalio.
        console.log("ACA 1");
        require(true, "Organization ID not found in db.");
        // require(_approval_threshold <= _owners.length, "INCORRECT_APPROVAL_THRESHOLD");

        console.log("ACA 1");
        bytes32 hash_id = keccak256(abi.encodePacked(_id));
        require(!organizationHashIds.contains(hash_id), "ORGANIZATION_ID_ALREADY_EXISTS");

        // Organization storage new_organization;
        Organization memory new_organization;

        new_organization.id = _id;
        new_organization.owners = _owners;
        new_organization.approval_threshold = _approval_threshold;
        new_organization.balance = 0;
        
        organizations[hash_id] = new_organization;
        bool res = organizationHashIds.add(hash_id);
        console.log("HASH: %s", res);
    }

    function totalOrganizations() external view returns (uint256) {
        return organizationHashIds.length();
    }

    function getOrganization(string memory _id) public view returns (Organization memory) {
        console.log("SUCCESS!");
        bytes32 hash_id = keccak256(abi.encodePacked(_id));
        if (organizationHashIds.contains(hash_id)) {
            Organization storage organization = organizations[hash_id];
            return organization;
        } else {
            revert("ORGANIZATION_ID_DOES_NOT_EXIST");
        }
    }
}