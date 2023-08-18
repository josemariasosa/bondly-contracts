// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./interfaces/IBondly.sol";
// import "./ERC4626Stakable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC4626.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title Bondly Resource Manager with Liquid Staking integration v0.4
/// @author alpha-centauri devs 🛰️

contract Bondly is IBondly {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // AggregatorV3Interface internal dataFeed;

    /// @notice Not for `v0.2.0`.
    // struct Organization {
    //     string id;
    //     address[] owners;
    //     uint256 approvalThreshold;
    //     uint256 balance;
    // }

    address public liquidStaking;

    enum MovementType {
        Payment,
        Stake,
        FastUnstake,
        Unstake
    }

    struct Project {
        bytes32 id;

        string name;
        string description;
        string organization;

        address[] owners;

        uint256 balanceEth;
        uint256 balanceStakedEth;
        uint256 balanceStable;
        IERC20 stableAddress;

        uint32 approvalThreshold;
    }

    struct Movement {
        bytes32 id;
        MovementType movementType;

        string name;
        string description;

        bytes32 projectId;
        uint256 amountEth;
        uint256 amountStakedEth;
        uint256 amountStable;
        address payTo;
        address proposedBy;
        address[] approvedBy;
        address[] rejectedBy;
        bool executed;
        bool rejected;
    }

    /// @notice Not for `v0.2.0`.
    // mapping(bytes32 => Organization) public organizations;
    // EnumerableSet.Bytes32Set private organizationHashIds;

    mapping(address => bytes32[]) public projectOwners;
    mapping(bytes32 => Project) public projects;
    EnumerableSet.Bytes32Set private projectHashIds;

    mapping(address => bytes32[]) public movementCreator;
    mapping(bytes32 => bytes32[]) public projectMovement;
    mapping(bytes32 => Movement) public movements;
    EnumerableSet.Bytes32Set private movementHashIds;

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
        ProjectJson memory project = getProject(_slug);
        if (!_accountInArray(msg.sender, project.owners)) { revert Unauthorized(); }
        _;
    }

    // modifier onlyAllowed(IERC20 _currency) {
    //     _assertAllowedCurrency(address(_currency));
    //     _;
    // }

    /// Network: Avax Fuji Testnet
    /// Aggregator: ETH/USD
    /// Address: 0x86d67c3D38D2bCeE722E601025C25a575021c6EA
    /// https://docs.chain.link/data-feeds/price-feeds/addresses?network=avalanche#Avalanche%20Testnet
    constructor() {
        // dataFeed = AggregatorV3Interface(
        //     0x86d67c3D38D2bCeE722E601025C25a575021c6EA
        // );
    }

    // function getLatestData() public view returns (int256) {
    //     (
    //         /* uint80 roundID */,
    //         int256 answer,
    //         /*uint startedAt*/,
    //         /*uint timeStamp*/,
    //         /*uint80 answeredInRound*/
    //     ) = dataFeed.latestRoundData();
    //     return answer;
    // }

    // *********************
    // * Core 🍒 Functions *
    // *********************

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

    function getAllProjectHashId(uint256 _index) public view returns (bytes32) {
        return projectHashIds.at(_index);
    }

    /// @notice The project slug MUST be unique.
    /// @param _slug a URL-friendly version of a string, example "hello-world".
    /// @param _owners do not forget to add the caller in the owners list.
    /// @param _approvalThreshold MultiSig M-N, the threshold is N.
    /// @param _currency if `_useAvax` is true, then this should be address(0).
    function createProject(
        string memory _name,
        string memory _description,
        string memory _organization,
        string memory _slug,
        address[] memory _owners,
        uint32 _approvalThreshold,
        address _currency
    ) public payable {
        if (_currency == address(0)) { revert InvalidZeroAddress(); }
        // require(_approvalThreshold <= _owners.length, "INCORRECT_APPROVAL_THRESHOLD");
        if (_approvalThreshold > _owners.length) { revert GenericError(); }
        // require(_approvalThreshold > 0, "approvalThreshold_CANNOT_BE_ZERO");
        if (_approvalThreshold == 0) { revert InvalidZeroAmount(); }

        bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        // require(!projectHashIds.contains(hash_id), "PROJECT_ID_ALREADY_EXISTS");
        if (projectHashIds.contains(hash_id)) { revert GenericError(); }

        Project memory new_project;
        new_project.id = hash_id;
        new_project.approvalThreshold = _approvalThreshold;
        new_project.stableAddress = IERC20(_currency);
        new_project.owners = _owners;

        /// WARNING: expensive on-chain storage.
        new_project.name = _name;
        new_project.description = _description;
        new_project.organization = _organization;

        projects[hash_id] = new_project;
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
        MovementType _movementType,
        string memory _name,
        string memory _description,
        string memory _movementSlug,
        string memory _projectSlug,
        uint256 _amountStable,
        uint256 _amountEth,
        uint256 _amountStakedEth,
        address _payTo
    ) external payable onlyProjectOwner(_projectSlug) {
        if (_movementType == MovementType.Payment) {
            if (_payTo == address(0)) { revert InvalidZeroAddress(); }
            if (_amountStable + _amountEth + _amountStakedEth == 0) {
                revert InvalidMovementZeroAmount();
            }
        } else {
            if (_amountStable > 0) { revert UnavailableStaking(); }
            if (_movementType == MovementType.Stake) {
                assert(_amountEth > 0 && _amountStakedEth == 0);
            } else {
                assert(_amountEth == 0 && _amountStakedEth > 0);
            }
        }

        bytes32 hash_id = keccak256(abi.encodePacked(_movementSlug));
        // require(!movementHashIds.contains(hash_id), "MOVEMENT_ID_ALREADY_EXISTS");
        if (movementHashIds.contains(hash_id)) { revert GenericError(); }

        bytes32 project_hash_id = keccak256(abi.encodePacked(_projectSlug));
        Project storage project = projects[project_hash_id];

        // require(project.balanceStable >= _amountStable, "NOT_ENOUGH_PROJECT_FUNDS");
        if (project.balanceStable < _amountStable) { revert NotEnoughBalance(); }
        // require(project.balanceEth >= _amountEth, "NOT_ENOUGH_PROJECT_FUNDS");
        if (project.balanceEth < _amountEth) { revert NotEnoughBalance(); }
        // require(project.balanceStakedEth >= _amountStakedEth, "NOT_ENOUGH_PROJECT_FUNDS");
        if (project.balanceStakedEth < _amountStakedEth) { revert NotEnoughBalance(); }

        project.balanceStable -= _amountStable;
        project.balanceEth -= _amountEth;
        project.balanceStakedEth -= _amountStakedEth;

        Movement memory new_movement;
        new_movement.id = hash_id;
        new_movement.projectId = project_hash_id;
        new_movement.amountStable = _amountStable;
        new_movement.amountEth = _amountEth;
        new_movement.amountStakedEth = _amountStakedEth;
        new_movement.payTo = _payTo;
        new_movement.proposedBy = msg.sender;

        /// WARNING: expensive on-chain storage.
        new_movement.name = _name;
        new_movement.description = _description;

        movements[hash_id] = new_movement;
        movementHashIds.add(hash_id);

        address[] memory _owners = project.owners;
        for (uint i = 0; i < _owners.length; ++i) {
            bytes32[] storage _projects = movementCreator[_owners[i]];
            _projects.push(hash_id);
        }

        bytes32[] storage _movements = projectMovement[project_hash_id];
        _movements.push(hash_id);
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
        uint256 _amountStable,
        uint256 _amountStakedEth
    ) public payable {
        require(projectHashIds.contains(_hash_id));
        uint256 _amountEth = msg.value;
        Project storage project = projects[_hash_id];

        if (_amountStable + _amountEth + _amountStakedEth == 0) {
            revert InvalidMovementZeroAmount();
        }

        project.balanceStable += _amountStable;
        project.balanceStakedEth += _amountStakedEth;
        project.balanceEth += _amountEth;

        bool _amountUpdated;
        if (_amountStable > 0) {
            project.stableAddress.safeTransferFrom(msg.sender, address(this), _amountStable);
            _amountUpdated = true;
        }

        if (_amountStakedEth > 0) {
            IERC20(liquidStaking).safeTransferFrom(msg.sender, address(this), _amountStakedEth);
            _amountUpdated = true;
        }

        if (_amountEth > 0) {
            _amountUpdated = true;
        }

        // Only work if some amount was updated.
        require(_amountUpdated);
    }

    function fundProject(
        string memory _projectSlug,
        uint256 _amountStable,
        uint256 _amountStakedEth
    ) public payable {
        bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
        fundProjectHash(hash_id, _amountStable, _amountStakedEth);
    }

    // *********************
    // * View 🛰️ Functions *
    // *********************

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

    function getProjectDetailsHash(
        bytes32 _hash_id
    ) public view returns (string memory, string memory, string memory) {
        Project memory project = _getProjectHash(_hash_id);
        return (project.name, project.description, project.organization);
    }

    function getProjectDetails(
        string memory _slug
    ) public view returns (string memory, string memory, string memory) {
        bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        Project memory project = _getProjectHash(hash_id);
        return (project.name, project.description, project.organization);
    }

    /// @notice getProjectHash (1 of 2)
    function _getProjectHash(bytes32 hash_id) private view returns (Project memory) {
         if (projectHashIds.contains(hash_id)) {
            Project memory project = projects[hash_id];
            return project;
        } else {
            revert ProjectNotFound(hash_id);
        }
    }

    /// @notice getProjectHash (2 of 2)
    function getProjectHash(bytes32 hash_id) public view returns(ProjectJson memory) {
        if (projectHashIds.contains(hash_id)) {
            Project memory project = projects[hash_id];
            ProjectJson memory result;
            result.id = project.id;
            result.owners = project.owners;
            result.approvalThreshold = project.approvalThreshold;
            result.stableAddress = address(project.stableAddress);
            result.balanceEth = project.balanceEth;
            result.balanceStakedEth = project.balanceStakedEth;
            result.balanceStable = project.balanceStable;
            // result.convertedStakedBalance = IERC4626(
            //     liquidStaking).convertToAssets(project.balanceStakedEth);
            return result;
        } else {
            revert ProjectNotFound(hash_id);
        }
    }

    function getProject(string memory _slug) public view returns (ProjectJson memory) {
        bytes32 hash_id = keccak256(abi.encodePacked(_slug));
        return getProjectHash(hash_id);
    }

    function getProjectBalanceStable(string memory _slug) public view returns (uint256) {
        return getProject(_slug).balanceStable;
    }

    function getProjectBalanceEth(string memory _slug) public view returns (uint256) {
        return getProject(_slug).balanceEth;
    }

    function getProjectBalanceStakedEth(string memory _slug) public view returns (uint256) {
        return getProject(_slug).balanceStakedEth;
    }

    function getProjectBalance(
        string memory _slug
    ) public view returns (uint256 _stable, uint256 _eth, uint256 _stakedEth) {
        _stable = getProjectBalanceStable(_slug);
        _eth = getProjectBalanceEth(_slug);
        _stakedEth = getProjectBalanceEth(_slug);
    }

    function getProjectThreshold(string memory _slug) public view returns (
        uint256 _totalOwners,
        uint256 _threshold,
        address _stableAddress
    ) {
        ProjectJson memory project = getProject(_slug);
        return (
            project.owners.length,
            project.approvalThreshold,
            project.stableAddress
        );
    }

    function getTotalProjects() external view returns (uint256) {
        return projectHashIds.length();
    }

    function getTotalMovements() external view returns (uint256) {
        return movementHashIds.length();
    }

    // *********************
    // * Private Functions *
    // *********************

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

    function _evaluateMovement(
        bytes32 _movementHashId,
        string memory _projectSlug
    ) private {
        Movement storage movement = movements[_movementHashId];
        (
            uint256 totalOwners,
            uint256 threshold,
            address stableAddress
        ) = getProjectThreshold(_projectSlug);
        // If the movement was already executed or rejected, then there is nothing to evaluate.
        if (!movement.executed && !movement.rejected) {
            if (movement.approvedBy.length >= (threshold - 1)) {
                movement.executed = true;
                if (movement.movementType == MovementType.Payment) {
                    _executePayment(movement, stableAddress);
                } else if (movement.movementType == MovementType.Stake) {
                    _executeStake(movement);
                } else if (movement.movementType == MovementType.Unstake) {
                    _executeUnstake(movement);
                } else if (movement.movementType == MovementType.FastUnstake) {
                    _executeFastUnstake(movement);
                }

            } else if (movement.rejectedBy.length > (totalOwners - threshold)) {
                movement.rejected = true;
                bytes32 hash_id = keccak256(abi.encodePacked(_projectSlug));
                Project storage project = projects[hash_id];
                project.balanceStable += movement.amountStable;
                project.balanceEth += movement.amountEth;
                project.balanceStakedEth += movement.amountStakedEth;
            }
        }
    }

    function _executeStake(Movement memory movement) private {
        (bool success, ) = liquidStaking.call{value: movement.amountEth}(
            abi.encodeWithSignature("depositEth()")
        );
        if (!success) { revert NotSuccessfulOperation(); }
    }

    function _executeUnstake(Movement memory movement) private {
        IERC4626(liquidStaking).redeem(
            movement.amountStakedEth,
            address(this),
            address(this)
        );
    }

    /// TODO: not implemented
    function _executeFastUnstake(Movement memory movement) private {
        IERC4626(liquidStaking).redeem(
            movement.amountStakedEth,
            address(this),
            address(this)
        );
    }

    function _executePayment(Movement memory movement, address stableAddress) private {
        // Stable coin: USD, MXN, ARG.
        uint256 _amountStable = movement.amountStable;
        if (_amountStable > 0) {
            IERC20(stableAddress).safeTransfer(movement.payTo, _amountStable);
        }

        uint256 _amountStakedEth = movement.amountStakedEth;
        if (_amountStakedEth > 0) {
            IERC20(liquidStaking).safeTransfer(movement.payTo, _amountStakedEth);
        }

        uint256 _amountEth = movement.amountEth;
        if (_amountEth > 0) {
            payable(movement.payTo).transfer(_amountEth);
        }
    }
}
