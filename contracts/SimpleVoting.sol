// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract SimpleVoting {
    // Necessary variables initialization
    address payable public admin;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        int256 votedProposalId;
    }
    mapping(address => Voter) public voters;

    struct Proposal {
        string description;
        uint256 voteCount;
    }
    Proposal[] public proposals;

    enum WorkFlowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    WorkFlowStatus public workFlowStatus;

    uint256 private winningProposalId;

    // Function Modifiers
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "This function can only be called by Admin."
        );
        _;
    }

    modifier onlyRegisteredVoter() {
        require(
            voters[msg.sender].isRegistered,
            "This method can only be called by the registered voters."
        );
        _;
    }

    modifier onlyDuringVotersRegistration() {
        require(
            workFlowStatus == WorkFlowStatus.RegisteringVoters,
            "This function can only be called before proposal registration has started"
        );
        _;
    }

    modifier onlyDuringProposalsRegistration() {
        require(
            workFlowStatus == WorkFlowStatus.ProposalsRegistrationStarted,
            "This function can only be called during proposal registration period."
        );
        _;
    }

    modifier onlyAfterProposalRegistration {
        require(
            workFlowStatus == WorkFlowStatus.ProposalsRegistrationEnded,
            "This function can only be called after the proposal registration has ended."
        );
        _;
    }

    modifier onlyDuringVotingSession {
        require(
            workFlowStatus == WorkFlowStatus.VotingSessionStarted,
            "This function can be called only during voting session."
        );

        _;
    }

    modifier onlyAfterVotingSession {
        require(
            workFlowStatus == WorkFlowStatus.VotingSessionEnded,
            "This function can be called only after voting session has ended."
        );
        _;
    }

    modifier onlyAfterVotesTailed {
        require(
            workFlowStatus == WorkFlowStatus.VotesTallied,
            "This function can only be called after votes have been tailed."
        );
        _;
    }

    // Events to be fired

    event VoterRegesteredEvent(address voterAddress);
    event ProposalsRegistrationStartedEvent();
    event ProposalRegisteredEvent(uint256 proposalId);
    event ProposalsRegistrationEndedEvent();
    event VotingSessionStartedEvent();
    event VotedEvent(address voter, uint256 proposalId);
    event VotingSessionEndedEvent();
    event VotesTailedEvent();
    event WorkFlowStatusChangedEvent(
        WorkFlowStatus prevStatus,
        WorkFlowStatus newStatus
    );

    constructor() public {
        admin = msg.sender;
        workFlowStatus = WorkFlowStatus.RegisteringVoters;
    }

    function registerVoter(address _voterAddress)
        public
        onlyAdmin
        onlyDuringVotersRegistration
    {
        require(
            !voters[_voterAddress].isRegistered,
            "The voter is already registered"
        );

        voters[_voterAddress].isRegistered = true;
        voters[_voterAddress].hasVoted = false;
        voters[_voterAddress].votedProposalId = -1;
    }

    function startProposalRegistration()
        public
        onlyAdmin
        onlyDuringVotersRegistration
    {
        workFlowStatus = WorkFlowStatus.ProposalsRegistrationStarted;

        emit ProposalsRegistrationStartedEvent();
        emit WorkFlowStatusChangedEvent(
            WorkFlowStatus.RegisteringVoters,
            workFlowStatus
        );
    }

    function registerProposal(string memory proposalDescription)
        public
        onlyRegisteredVoter
        onlyDuringProposalsRegistration
    {
        proposals.push(
            Proposal({description: proposalDescription, voteCount: 0})
        );

        emit ProposalRegisteredEvent(proposals.length - 1);
    }

    function endProposalRegistration()
        public
        onlyAdmin
        onlyDuringProposalsRegistration
    {
        workFlowStatus = WorkFlowStatus.ProposalsRegistrationEnded;

        emit ProposalsRegistrationStartedEvent();
        emit WorkFlowStatusChangedEvent(
            WorkFlowStatus.ProposalsRegistrationStarted,
            workFlowStatus
        );
    }

    function startVotingSession()
        public
        onlyAdmin
        onlyAfterProposalRegistration
    {
        workFlowStatus = WorkFlowStatus.VotingSessionStarted;

        emit VotingSessionStartedEvent();
        emit WorkFlowStatusChangedEvent(
            WorkFlowStatus.ProposalsRegistrationEnded,
            workFlowStatus
        );
    }

    function vote(uint256 proposalId)
        public
        onlyRegisteredVoter
        onlyDuringVotingSession
    {
        require(proposalId < proposals.length);
        require(!voters[msg.sender].hasVoted, "Already Voted from this ID");

        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = int256(proposalId);

        proposals[proposalId].voteCount += 1;

        emit VotedEvent(msg.sender, proposalId);
    }

    function endVotingSession() public onlyAdmin onlyDuringVotingSession {
        workFlowStatus = WorkFlowStatus.VotingSessionEnded;

        emit VotingSessionStartedEvent();
        emit WorkFlowStatusChangedEvent(
            WorkFlowStatus.VotingSessionStarted,
            workFlowStatus
        );
    }

    function tallyVotes() public onlyAdmin onlyAfterVotingSession {
        uint256 winningVoteCount = 0;
        uint256 winningProposalIndex = 0;

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalIndex = i;
            }
        }

        winningProposalId = winningProposalIndex;
        workFlowStatus = WorkFlowStatus.VotesTallied;

        emit VotesTailedEvent();
        emit WorkFlowStatusChangedEvent(
            WorkFlowStatus.VotingSessionEnded,
            workFlowStatus
        );
    }

    function getNumberOfProposals() public view returns (uint256) {
        return proposals.length;
    }

    function getProposalDescription(uint256 index)
        public
        view
        returns (string memory)
    {
        return proposals[index].description;
    }

    function getWinningProposalId()
        public
        view
        onlyAfterVotesTailed
        returns (uint256)
    {
        return winningProposalId;
    }

    function getWinningProposalDescription()
        public
        view
        onlyAfterVotesTailed
        returns (string memory)
    {
        return proposals[winningProposalId].description;
    }

    function getWinningProposalVoteCounts()
        public
        view
        onlyAfterVotesTailed
        returns (uint256)
    {
        return uint256(proposals[winningProposalId].voteCount);
    }

    function isRegisteredVoter(address _voterAddress)
        public
        view
        returns (bool)
    {
        return voters[_voterAddress].isRegistered;
    }

    function isAdmin(address _address) public view returns (bool) {
        return _address == admin;
    }

    function getWorkFlowStatus() public view returns (WorkFlowStatus) {
        return workFlowStatus;
    }
}
