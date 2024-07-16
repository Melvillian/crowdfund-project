// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC721} from "solmate/tokens/ERC721.sol";

/**
 * @title Project
 * @dev A contract that represents a project with a funding goal. It inherits from the ERC721 contract.
 */
contract Project is ERC721 {
    uint256 public constant MIN_CONTRIBUTION = 0.01 ether;

    uint256 public immutable goal;

    address public immutable creator;

    uint256 public immutable endDate;

    uint256 public nftsMinted;

    bool public isCancelled;

    uint256 public totalContributed;

    /**
     * @dev Mapping that tracks the balances of contributors to the project.
     */
    mapping(address => uint256) public balances;

    /**
     * @dev Mapping that tracks the number of NFTs owed to each contributor.
     */
    mapping(address => uint256) public nftsOwed;

    error GoalTooLow(uint256 amount);
    error ContributionTooLow(uint256 amount);
    error WithdrawAmountTooLarge(uint256 amount);
    error NoNftsToClaim();
    error ProjectAlreadyFunded();
    error OnlyCreatorCanCancelProject();
    error ProjectCancelled();
    error ProjectPastEnddate(uint256 endDate, uint256 currentDate);
    error ProjectMustBeFailed();

    event ProjectCreated(address indexed creator, uint256 goal);
    event Contributed(address indexed contributor, uint256 amount, uint256 newNfts);
    event EthWithdrawn(address withdrawer, uint256 amount);
    event NftsClaimed(address claimer, uint256 numClaimed);
    event Cancelled();
    event GoalReached(uint256 total);

    constructor(string memory _name, string memory _symbol, uint256 _goal, address _creator) ERC721(_name, _symbol) {
        require(_goal >= MIN_CONTRIBUTION, GoalTooLow(_goal));
        goal = _goal;
        creator = _creator;
        endDate = block.timestamp + 30 days;

        emit ProjectCreated(_creator, _goal);
    }

    modifier projectHasNotFailed() {
        require(block.timestamp <= endDate, ProjectPastEnddate(endDate, block.timestamp));
        require(!isCancelled, ProjectCancelled());

        _;
    }

    modifier projectHasFailed() {
        require(block.timestamp > endDate || isCancelled, ProjectMustBeFailed());

        _;
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {}

    function isFunded() public view returns (bool) {
        return totalContributed >= goal;
    }

    function contribute() public payable virtual projectHasNotFailed {
        require(totalContributed < goal, ProjectAlreadyFunded());
        uint256 amount = msg.value;
        require(amount >= MIN_CONTRIBUTION, ContributionTooLow(amount));

        uint256 newNftsOwed = ((balances[msg.sender] + amount) / 1 ether) - (balances[msg.sender] / 1 ether);
        nftsOwed[msg.sender] += newNftsOwed;
        balances[msg.sender] += amount;
        totalContributed += amount;

        emit Contributed(msg.sender, amount, newNftsOwed);

        if (isFunded()) {
            emit GoalReached(totalContributed);
        }
    }

    function withdrawEth(uint256 _amount) external projectHasFailed {
        require(totalContributed < goal, ProjectAlreadyFunded());

        // this will revert if the user tries to withdraw more than they have
        balances[msg.sender] -= _amount;

        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Failed to withdraw Ether");

        emit EthWithdrawn(msg.sender, _amount);
    }

    function cancelProject() external projectHasNotFailed {
        require(totalContributed < goal, ProjectAlreadyFunded());
        require(msg.sender == creator, OnlyCreatorCanCancelProject());

        isCancelled = true;

        emit Cancelled();
    }

    function claimNfts() public {
        uint256 numToClaim = nftsOwed[msg.sender];
        require(numToClaim > 0, NoNftsToClaim());

        nftsOwed[msg.sender] = 0;

        for (uint256 i = 0; i < numToClaim; i++) {
            _safeMint(msg.sender, nftsMinted++);
        }

        emit NftsClaimed(msg.sender, numToClaim);
    }
}
