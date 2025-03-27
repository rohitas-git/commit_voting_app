// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AnonymousVoting {
    enum Phase { Commit, Reveal, Ended }
    Phase public phase;

    uint256 public commitDeadline;
    uint256 public revealDeadline;

    mapping(address => bytes32) public commitments;
    mapping(address => bool) public revealed;

    mapping(string => uint256) public voteCounts;

    uint256 public totalVotes;
    uint256 public totalParticipants;

    address public owner;

    event VoteRevealed(address indexed voter, string vote);
    event VoteCommitted(address indexed voter);

    constructor(uint256 _commitDuration, uint256 _revealDuration) {
        owner = msg.sender;
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = commitDeadline + _revealDuration;
        phase = Phase.Commit;
    }

    modifier onlyInPhase(Phase _phase) {
        require(phase == _phase, "Wrong phase");
        _;
    }

    function updatePhase() public {
        if (block.timestamp > revealDeadline) {
            phase = Phase.Ended;
        } else if (block.timestamp > commitDeadline) {
            phase = Phase.Reveal;
        }
    }

    function commitVote(bytes32 _commitment) external {
        updatePhase();
        require(phase == Phase.Commit, "Not in commit phase");
        require(commitments[msg.sender] == 0, "Already committed");
        commitments[msg.sender] = _commitment;
        emit VoteCommitted(msg.sender);
    }

    function revealVote(string memory _vote, string memory _salt) external {
        updatePhase();
        require(phase == Phase.Reveal, "Not in reveal phase");
        require(!revealed[msg.sender], "Already revealed");
        bytes32 expected = keccak256(abi.encodePacked(_vote, _salt));
        require(commitments[msg.sender] == expected, "Invalid reveal");

        voteCounts[_vote]++;
        totalVotes++;
        totalParticipants++;
        revealed[msg.sender] = true;
        emit VoteRevealed(msg.sender, _vote);
    }

    function getVoteCount(string memory _vote) external view returns (uint256) {
        return voteCounts[_vote];
    }

    function getHash(string memory _vote, string memory _salt) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_vote, _salt));
    }

    function restart(uint256 _commitDuration, uint256 _revealDuration) external {
        commitDeadline = block.timestamp + _commitDuration;
        revealDeadline = commitDeadline + _revealDuration;
        phase = Phase.Commit;
    }

    function getCurrentPhase() external view returns (Phase) {
        if (block.timestamp > revealDeadline) return Phase.Ended;
        if (block.timestamp > commitDeadline) return Phase.Reveal;
        return Phase.Commit;
    }
}