// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

// import "./interfaces/IStakingManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

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
        string projectId;
        uint256 amount;
        address payTo;
        address proposedBy;
        address[] approvedBy;
        address[] rejectedBy;
        bool payed;
    }

    mapping(bytes32 => Organization) public organizations;
    EnumerableSet.Bytes32Set private organizationHashIds;

    mapping(bytes32 => Project) public projects;
    EnumerableSet.Bytes32Set private projectHashIds;

    mapping(bytes32 => Movement) public movements;
    EnumerableSet.Bytes32Set private movementHashIds;

    address public immutable baseToken;

    modifier onlyOrganizationOwner(string memory _organizationId) {
        Organization memory organization = getOrganization(_organizationId);
        require(
            _accountInArray(msg.sender, organization.owners),
            "ACCOUNT_IS_NOT_AN_OWNER"
        );
        _;
    }

    constructor(address _baseToken) {
        require(_baseToken != address(0));
        baseToken = _baseToken;
    }

    function createOrganization(
        string memory _id,
        address[] memory _owners,
        uint256 _approval_threshold
    ) external onlyOwner {
        // TODO: require the _id to exist in Cedalio.
        require(true, "Organization ID not found in db.");
        require(_approval_threshold <= _owners.length, "INCORRECT_APPROVAL_THRESHOLD");

        bytes32 hash_id = keccak256(abi.encodePacked(_id));
        require(!organizationHashIds.contains(hash_id), "ORGANIZATION_ID_ALREADY_EXISTS");

        Organization memory new_organization;
        new_organization.id = _id;
        new_organization.owners = _owners;
        new_organization.approval_threshold = _approval_threshold;
        new_organization.balance = 0;
        
        organizations[hash_id] = new_organization;
        organizationHashIds.add(hash_id);
    }

    function createProject(
        string memory _projectId,
        string memory _organizationId
    ) external onlyOrganizationOwner(_organizationId) {
        bytes32 hash_id = keccak256(abi.encodePacked(_projectId));
        require(!projectHashIds.contains(hash_id), "PROJECT_ID_ALREADY_EXISTS");

        Project memory new_project;
        new_project.id = _projectId;
        new_project.organizationId = _organizationId;

        projects[hash_id] = new_project;
        projectHashIds.add(hash_id);
    }

    function createMovement(
        string memory _movementId,
        string memory _projectId,
        string memory _organizationId,
        uint256 _amount,
        address _payTo
    ) external onlyOrganizationOwner(_organizationId) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementId));
        require(!movementHashIds.contains(hash_id), "MOVEMENT_ID_ALREADY_EXISTS");

        Organization storage organization = organizations[hash_id];
        require(organization.balance >= _amount, "NOT_ENOUGH_ORGANIZATION_FUNDS");
        organization.balance -= _amount;

        Movement memory new_movement;
        new_movement.id = _movementId;
        new_movement.projectId = _projectId;
        new_movement.amount = _amount;
        new_movement.payTo = _payTo;
        new_movement.proposedBy = msg.sender;

        movements[hash_id] = new_movement;
        movementHashIds.add(hash_id);
    }

    function getOrganization(string memory _id) public view returns (Organization memory) {
        bytes32 hash_id = keccak256(abi.encodePacked(_id));
        if (organizationHashIds.contains(hash_id)) {
            Organization memory organization = organizations[hash_id];
            return organization;
        } else {
            revert("ORGANIZATION_ID_DOES_NOT_EXIST");
        }
    }

    function totalOrganizations() external view returns (uint256) {
        return organizationHashIds.length();
    }

    function totalProjects() external view returns (uint256) {
        return projectHashIds.length();
    }

    function totalMovements() external view returns (uint256) {
        return movementHashIds.length();
    }

    function _accountInArray(
        address _account,
        address[] memory _array
    ) private pure returns (bool) {
        bool doesListContainElement = false;
        for (uint256 i=0; i < _array.length; i++) {
            if (_account == _array[i]) {
                doesListContainElement = true;
                break;
            }
        }
        return doesListContainElement;
    }
}