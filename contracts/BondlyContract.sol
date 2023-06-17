// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IBondlyContract.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// import "hardhat/console.sol";

contract BondlyContract is IBondlyContract {
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
    uint256 immutable public movementCreationFee;
    uint256 public collectedFees;

    struct Project {
        bytes32 id;
        // bytes32 organizationId;
        address[] owners;
        uint32 approvalThreshold;

        uint256 balanceAvax;
        uint256 balanceStable;
        IERC20 stableAddress;
    }

    struct Movement {
        bytes32 id;
        bytes32 projectId;
        uint256 amountAvax;
        uint256 amountStable;
        address payTo;
        address proposedBy;
        address[] approvedBy;
        address[] rejectedBy;
        bool payed;
        bool rejected;
    }

    /// @notice Not for `v0.2.0`.
    // mapping(bytes32 => Organization) public organizations;
    // EnumerableSet.Bytes32Set private organizationHashIds;

    mapping(address => bytes32[]) public projectOwners;
    mapping(bytes32 => Project) public projects;
    EnumerableSet.Bytes32Set private projectHashIds;

    mapping(address => bytes32[]) public movementCreator;
    mapping(bytes32 => Movement) public movements;
    EnumerableSet.Bytes32Set private movementHashIds;

    IERC20[] public allowedCurrency;

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

    constructor(
        IERC20[] memory _allowedCurrency,
        uint256 _projectCreationFee,
        uint256 _movementCreationFee
    ) {
        if (_allowedCurrency.length > MAX_CURRENCIES) { revert InvalidSizeLimit(); }
        for (uint i = 0; i < _allowedCurrency.length; ++i) {
            address _currency = address(_allowedCurrency[i]);
            if (_currency == address(0)) { revert InvalidZeroAddress(); }

            if (isAllowed(_currency)) {
                revert AlreadyAllowed(_currency);
            } else {
                allowedCurrency.push(IERC20(_currency));
            }
        }

        projectCreationFee = _projectCreationFee;
        movementCreationFee = _movementCreationFee;
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

    /// @notice The project slug MUST be unique.
    /// @param _projectSlug a URL-friendly version of a string, example "hello-world".
    /// @param _owners do not forget to add the caller in the owners list.
    /// @param _approvalThreshold MultiSig M-N, the threshold is N.
    /// @param _currency if `_useAvax` is true, then this should be address(0).
    function createProject(
        string memory _projectSlug,
        address[] memory _owners,
        uint32 _approvalThreshold,
        address _currency
    ) public payable {
        _chargeFee(projectCreationFee);

        if (_currency != address(0)) { _assertAllowedCurrency(_currency); }

        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        require(!projectHashIds.contains(hash_id), "PROJECT_ID_ALREADY_EXISTS");

        Project memory new_project;
        new_project.id = hash_id;
        new_project.approvalThreshold = _approvalThreshold;
        new_project.balanceAvax = 0;
        new_project.balanceStable = 0;
        new_project.stableAddress = IERC20(_currency);
        
        // 👀 CAUTION: The logic is to insert all the owners into the new project.
        new_project.owners = _owners;

        projects[hash_id] = new_project;
        // for (uint i = 0; i < _owners.length; ++i) {
        //     projects[hash_id].owners.push(_owners[i]);
        // } 

        projectHashIds.add(hash_id);

        for (uint i = 0; i < _owners.length; ++i) {
            bytes32[] storage _projects = projectOwners[_owners[i]];
            _projects.push(hash_id);
        }
    }

    function updateProjectStableAddress(
        string memory _projectSlug,
        address _newCurrency
    ) public onlyProjectOwner(_projectSlug) {
        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        Project storage project = projects[hash_id];
        if (project.balanceStable > 0) { revert InvalidBalanceAmount(); }
        project.stableAddress = IERC20(_newCurrency);
    }

    function createMovement(
        string memory _movementSlug,
        string memory _projectSlug,
        uint256 _amountStable,
        uint256 _amountAvax,
        address _payTo
    ) external payable onlyProjectOwner(_projectSlug) {
        _chargeFee(movementCreationFee);

        bytes32 hash_id = keccak256(abi.encodePacked(_movementSlug));
        require(!movementHashIds.contains(hash_id), "MOVEMENT_ID_ALREADY_EXISTS");

        bytes32 project_hash_id = keccak256(abi.encodePacked(_projectSlug));
        Project storage project = projects[project_hash_id];

        require(project.balanceStable >= _amountStable, "NOT_ENOUGH_PROJECT_FUNDS");
        require(project.balanceAvax >= _amountAvax, "NOT_ENOUGH_PROJECT_FUNDS");

        project.balanceStable -= _amountStable;
        project.balanceAvax -= _amountAvax;

        Movement memory new_movement;
        new_movement.id = hash_id;
        new_movement.projectId = project_hash_id;
        new_movement.amountStable = _amountStable;
        new_movement.amountAvax = _amountAvax;
        new_movement.payTo = _payTo;
        new_movement.proposedBy = msg.sender;

        movements[hash_id] = new_movement;
        movementHashIds.add(hash_id);

        address[] memory _owners = project.owners;
        for (uint i = 0; i < _owners.length; ++i) {
            bytes32[] storage _projects = movementCreator[_owners[i]];
            _projects.push(hash_id);
        }
    }

    function approveMovement(
        string memory _movementSlug,
        string memory _projectSlug
    ) external onlyProjectOwner(_projectSlug) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementSlug));
        require(movementHashIds.contains(hash_id), "MOVEMENT_ID_DOES_NOT_EXIST");
        Movement storage movement = movements[hash_id];

        require(msg.sender != movement.proposedBy, "CANNOT_BE_PROPOSED_AND_APPROVED_BY_SAME_USER");
        require(!_accountInArray(msg.sender, movement.approvedBy), "USER_ALREADY_APPROVED_MOVEMENT");
        require(!_accountInArray(msg.sender, movement.rejectedBy), "USER_ALREADY_REJECTED_MOVEMENT");

        movement.approvedBy.push(msg.sender);
        _evaluateMovement(hash_id, _projectSlug);
    }

    function rejectMovement(
        string memory _movementSlug,
        string memory _projectSlug
    ) external onlyProjectOwner(_projectSlug) {
        bytes32 hash_id = keccak256(abi.encodePacked(_movementSlug));
        require(movementHashIds.contains(hash_id), "MOVEMENT_ID_DOES_NOT_EXIST");
        Movement storage movement = movements[hash_id];

        require(msg.sender != movement.proposedBy, "CANNOT_BE_PROPOSED_AND_REJECTED_BY_SAME_USER");
        require(!_accountInArray(msg.sender, movement.approvedBy), "USER_ALREADY_APPROVED_MOVEMENT");
        require(!_accountInArray(msg.sender, movement.rejectedBy), "USER_ALREADY_REJECTED_MOVEMENT");

        movement.rejectedBy.push(msg.sender);
        _evaluateMovement(hash_id, _projectSlug);
    }

    /// @param _hash_id must be from an existing project.
    function fundProjectHash(
        bytes32 _hash_id,
        uint256 _amountStable
    ) public payable {
        require(projectHashIds.contains(_hash_id));
        uint256 _amountAvax = msg.value;
        Project storage project = projects[_hash_id];

        bool _amountUpdated;
        if (_amountStable > 0) {
            project.stableAddress.safeTransferFrom(msg.sender, address(this), _amountStable);
            project.balanceStable += _amountStable;
            _amountUpdated = true;
        }

        if (_amountAvax > 0) {
            project.balanceAvax += _amountAvax;
            _amountUpdated = true;
        }

        // Only work if some amount was updated.
        require(_amountUpdated);
    }

    function fundProject(string memory _projectSlug, uint256 _amountStable) public payable {
        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        fundProjectHash(hash_id, _amountStable);
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

    function getProjectHash(bytes32 hash_id) public view returns(Project memory) {
        if (projectHashIds.contains(hash_id)) {
            Project memory project = projects[hash_id];
            return project;
        } else {
            revert ProjectNotFound(hash_id);
        }
    }

    function getProject(string memory _slug) public view returns (Project memory) {
        bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        return getProjectHash(hash_id);
    }

    function getProjectBalanceStable(string memory _slug) public view returns (uint256) {
        return getProject(_slug).balanceStable;
    }

    function getProjectThreshold(
        string memory _slug
    ) public view returns (uint256 _totalOwners, uint256 _threshold, IERC20 _stableAddress) {
        Project memory project = getProject(_slug);
        return (project.owners.length, project.approvalThreshold, project.stableAddress);
    }

    function getTotalProjects() external view returns (uint256) {
        return projectHashIds.length();
    }

    function getTotalMovements() external view returns (uint256) {
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

    function _evaluateMovement(bytes32 _movementHashId, string memory _projectSlug) private {
        Movement storage movement = movements[_movementHashId];
        (uint256 totalOwners, uint256 threshold, IERC20 stableAddress) = getProjectThreshold(_projectSlug);
        // If the movement was already payed or rejected, then there is nothing to evaluate.
        if (!movement.payed && !movement.rejected) {
            if (movement.approvedBy.length >= (threshold - 1)) {
                movement.payed = true;

                // Stable coin: USD, MXN, ARG.
                uint256 _amountStable = movement.amountStable;
                if (_amountStable > 0) {
                    stableAddress.safeTransfer(movement.payTo, _amountStable);
                }

                uint256 _amountAvax = movement.amountAvax;
                if (_amountAvax > 0) {
                    payable(movement.payTo).transfer(_amountAvax);
                }
            } else if (movement.rejectedBy.length > (totalOwners - threshold)) {
                movement.rejected = true;
                bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
                Project storage project = projects[hash_id];
                project.balanceStable += movement.amountStable;
                project.balanceAvax += movement.amountAvax;
            }
        }
    }

    function isAllowed(address _currency) public view returns (bool) {
        IERC20[] memory _allowedCurrency = allowedCurrency;
        address[] memory _currencies = new address[](_allowedCurrency.length);

        for (uint i = 0; i < _allowedCurrency.length; i++) {
            _currencies[i] = address(_allowedCurrency[i]);
        }

        return _accountInArray(_currency, _currencies);
    }

    function _assertAllowedCurrency(address _currency) internal view {
        if (!isAllowed(_currency)) { revert UnavailableCurrency(_currency); }
    }

    function _chargeFee(uint256 _fee) private {
        require(msg.value >= _fee, "Not enough AVAX sent.");

        collectedFees += _fee;
        uint256 amountToReturn = msg.value - _fee;
        if (amountToReturn > 0) {
            payable(msg.sender).transfer(amountToReturn);
        }
    }
}