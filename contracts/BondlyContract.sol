// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

contract BondlyContract {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    uint32 constant public MAX_CURRENCIES = 3;

    /// @notice Not for `v0.2.0`.
    // struct Organization {
    //     string id;
    //     address[] owners;
    //     uint256 approvalThreshold;
    //     uint256 balance;
    // }

    /// @notice Payed in AVAX - base asset.
    uint256 immutable public projectCreationFee;
    uint256 public collectedFees;

    struct Project {
        bytes32 id;
        // bytes32 organizationId;
        address[] owners;
        uint32 approvalThreshold;

        uint256 balanceAvax;
        uint256 balanceStable;
        address stableAddress;
    }

    struct Movement {
        bytes32 id;
        bytes32 projectId;
        uint256 amount;
        address payTo;
        address proposedBy;
        address[] approvedBy;
        address[] rejectedBy;
        bool payed;
        bool rejected;
    }

    error InvalidZeroAddress();
    error AlreadyAllowed(address _currency);
    error InvalidSizeLimit();
    error InvalidBalanceAmount();
    error UnavailableCurrency(address _currency);
    error ProjectNotFound(bytes32 memory _hash_id);

    /// @notice Not for `v0.2.0`.
    // mapping(bytes32 => Organization) public organizations;
    // EnumerableSet.Bytes32Set private organizationHashIds;

    mapping(bytes32 => Project) public projects;
    EnumerableSet.Bytes32Set private projectHashIds;

    mapping(bytes32 => Movement) public movements;
    EnumerableSet.Bytes32Set private movementHashIds;

    address public immutable baseToken;

    IERC20[] public allowedCurrency;

    mapping(bytes32 => mapping(address => uint256)) public projectBalances;

    /// @notice Not for `v0.2.0`.
    // modifier onlyOrganizationOwner(string memory _organizationId) {
    //     Organization memory organization = getOrganization(_organizationId);
    //     require(
    //         _accountInArray(msg.sender, organization.owners),
    //         "ACCOUNT_IS_NOT_AN_OWNER"
    //     );
    //     _;
    // }

    modifier onlyProjectOwner(string memory _slug) {
        Project memory project = getProject(_slug);
        require(
            _accountInArray(msg.sender, project.owners),
            "ACCOUNT_IS_NOT_AN_OWNER"
        );
        _;
    }

    function isAllowed(address _currency) public view returns (bool) {
        IERC20[] memory _currencies = allowedCurrency;
        return _accountInArray(_currency, _currencies);
    }

    constructor(
        IERC20[] memory _allowedCurrency,
        uint256 _projectCreationFee,
    ) {
        if (_allowedCurrency.length > MAX_CURRENCIES) { revert InvalidSizeLimit(); }
        for (int i = 0; i <= _allowedCurrency.length; ++i) {
            address _currency = address(_allowedCurrency[i]);
            if _currency == address(0) { revert InvalidZeroAddress(); }

            if isAllowed(_currency) {
                revert AlreadyAllowed(_currency);
            } else {
                allowedCurrency.push(IERC20(_currency))
            }
        }

        projectCreationFee = _projectCreationFee;
    }

    /// @notice Not for `v0.2.0`.
    // function createOrganization(
    //     string memory _id,
    //     address[] memory _owners,
    //     uint256 _approvalThreshold
    // ) external onlyOwner {
    //     // TODO: require the _id to exist in Cedalio.
    //     require(true, "Organization ID not found in db.");
    //     require(_approvalThreshold <= _owners.length, "INCORRECT_approvalThreshold");
    //     require(_approvalThreshold > 0, "approvalThreshold_CANNOT_BE_ZERO");

    //     bytes32 hash_id = keccak256(abi.encodePacked(_id));
    //     require(!organizationHashIds.contains(hash_id), "ORGANIZATION_ID_ALREADY_EXISTS");

    //     Organization memory new_organization;
    //     new_organization.id = _id;
    //     new_organization.owners = _owners;
    //     new_organization.approvalThreshold = _approvalThreshold;
    //     new_organization.balance = 0;
        
    //     organizations[hash_id] = new_organization;
    //     organizationHashIds.add(hash_id);
    // }

    function _assertAllowedCurrency(address _currency) internal {
        if (!isAllowed(_currency)) { revert UnavailableCurrency(_currency); }
    }

    function _chargeCreateProjectFee() private {
        uint256 _fee = projectCreationFee;
        require(msg.value >= projectCreationFee, "Not enough AVAX sent.");

        collectedFees += projectCreationFee;
        uint256 amountToReturn = msg.value - _fee;
        if (amountToReturn > 0) {
            msg.sender.transfer(amountToReturn);
        }
    }

    /// @notice The project slug MUST be unique.
    /// @param _projectSlug a URL-friendly version of a string, example "hello-world".
    /// @param _useAvax if false, then the project will use the erc20 address.
    /// @param _currency if `_useAvax` is true, then this should be address(0).
    function createProject(
        // @notice Not for `v0.2.0`.
        // string memory _organizationId,
        string memory _projectSlug,
        address[] memory _owners,
        uint32 _approvalThreshold,
        address _currency,
    ) public payable {
        if (_currency != address(0)) { _assertAllowedCurrency(_currency); }

        _chargeCreateProjectFee();

        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        require(!projectHashIds.contains(hash_id), "PROJECT_ID_ALREADY_EXISTS");

        Project memory new_project;
        new_project.id = hash_id;
        new_project.approvalThreshold = _approvalThreshold;
        new_project.balanceAvax = 0;
        new_project.balanceStable = 0;
        new_project.stableAddress = _currency;

        for (uint i = 0; i < _owners.length; ++i) {
            new_project.owners.push(_owners[i])
        } 

        projects[hash_id] = new_project;
        projectHashIds.add(hash_id);
    }

    function updateProjectStableAddress(
        string memory _projectSlug,
        address _newCurrency,
    ) public onlyProjectOwner(_projectSlug) {
        if (balanceStable > 0) { revert InvalidBalanceAmount(); }
        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        Project storage project = projects[hash_id];
        project.stableAddress = _newCurrency;
    }

    function createMovement(
        string memory _movementSlug,
        string memory _projectSlug,
        uint256 _amount,
        address _payTo
    ) external onlyProjectOwner(_projectSlug) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementId));
        require(!movementHashIds.contains(hash_id), "MOVEMENT_ID_ALREADY_EXISTS");

        bytes32 organization_hash_id = keccak256(abi.encodePacked(_organizationId));
        Organization storage organization = organizations[organization_hash_id];
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

    function approveMovement(
        string memory _movementId,
        string memory _organizationId
    ) external onlyOrganizationOwner(_organizationId) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementId));
        require(movementHashIds.contains(hash_id), "MOVEMENT_ID_DOES_NOT_EXIST");
        Movement storage movement = movements[hash_id];

        require(msg.sender != movement.proposedBy, "CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");
        require(!_accountInArray(msg.sender, movement.approvedBy), "USER_ALREADY_APPROVED_MOVEMENT");
        require(!_accountInArray(msg.sender, movement.rejectedBy), "USER_ALREADY_REJECTED_MOVEMENT");

        movement.approvedBy.push(msg.sender);
        _evaluateMovement(hash_id, _organizationId);
    }

    function rejectMovement(
        string memory _movementId,
        string memory _organizationId
    ) external onlyOrganizationOwner(_organizationId) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementId));
        require(movementHashIds.contains(hash_id), "MOVEMENT_ID_DOES_NOT_EXIST");
        Movement storage movement = movements[hash_id];

        require(msg.sender != movement.proposedBy, "CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");
        require(!_accountInArray(msg.sender, movement.approvedBy), "USER_ALREADY_APPROVED_MOVEMENT");
        require(!_accountInArray(msg.sender, movement.rejectedBy), "USER_ALREADY_REJECTED_MOVEMENT");

        movement.rejectedBy.push(msg.sender);
        _evaluateMovement(hash_id, _organizationId);
    }

    /// @param _hash_id must be from an existing project.
    /// @param _stableAddress if address(0), then the funding is in AVAX.
    function fundProjectHash(
        bytes32 memory _hash_id,
        uint256 _amountStable,
        IERC20 _stableAddress,
    ) public payable {

        require(projectHashIds.contains(hash_id));
        uint256 _amountAvax = msg.value;

        Organization storage project = projects[hash_id];

        bool _amountUpdated;
        if (_amountStable > 0) {
            require(_stableAddress == project.stableAddress);
            _stableAddress.safeTransferFrom(msg.sender, address(this), _amountStable);
            project.balanceStable += _amountStable;
            _amountUpdated = true;
        }

        if (_amountAvax > 0) {
            project.balanceAvax += _amountAvax;
            _amountUpdated = true;
        }

    }

    function fundProject(string memory _projectSlug, uint256 _amount) public payable {
        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        return fundProjectHash(hash_id);

    }

    /// @notice Not for `v0.2.0`.
    // function getOrganization(string memory _id) public view returns (Organization memory) {
    //     bytes32 hash_id = keccak256(abi.encodePacked(_id));
    //     if (organizationHashIds.contains(hash_id)) {
    //         Organization memory organization = organizations[hash_id];
    //         return organization;
    //     } else {
    //         revert("ORGANIZATION_ID_DOES_NOT_EXIST");
    //     }
    // }

    function getProjectHash(bytes32 memory hash_id) public view returns(Project memory) {
        if (projectHashIds.contains(hash_id)) {
            Project memory project = projects[hash_id];
            return project;
        } else {
            revert ProjectNotFound(hash_id);
        }
    }

    function getProject(string memory _slug) public view returns (Project memory) {
        bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        return getProjectHash(hash_id)
        
    }

    function getOrganizationBalance(string memory _id) public view returns (uint256) {
        return getOrganization(_id).balance;
    }

    function getOrganizationThreshold(
        string memory _id
    ) public view returns (uint256 _totalOwners, uint256 _threshold) {
        Organization memory organization = getOrganization(_id);
        return (organization.owners.length, organization.approvalThreshold);
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
        for (uint i=0; i < _array.length; i++) {
            if (_account == _array[i]) {
                doesListContainElement = true;
                break;
            }
        }
        return doesListContainElement;
    }

    function _evaluateMovement(bytes32 _movementHashId, string memory _organizationId) private {
        Movement storage movement = movements[_movementHashId];
        (uint256 totalOwners, uint256 threshold) = getOrganizationThreshold(_organizationId);
        // If the movement was already payed or rejected, then there is nothing to evaluate.
        if (!movement.payed && !movement.rejected) {
            if (movement.approvedBy.length >= (threshold - 1)) {
                movement.payed = true;
                IERC20(baseToken).safeTransfer(movement.payTo, movement.amount);
            } else if (movement.rejectedBy.length > (totalOwners - threshold)) {
                movement.rejected = true;
                bytes32 hash_id = keccak256(abi.encodePacked(_organizationId));
                Organization storage organization = organizations[hash_id];
                organization.balance += movement.amount;
            }
        }
    }
}