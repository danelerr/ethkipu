// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ElectoralSystem
 * @dev Sistema de votación electoral descentralizada
 * @author Daniel Cueto
 * @notice Este contrato gestiona un proceso electoral completo con fases, candidatos y votantes
 */
contract ElectoralSystem {
    
    // ==================== EVENTOS ====================

    /**
     * @dev Emitido cuando se añade un nuevo candidato
     * @param candidateId ID único del candidato
     * @param name Nombre del candidato
     */
    event CandidateAdded(uint256 indexed candidateId, string name);

    /**
     * @dev Emitido cuando se autoriza a un nuevo votante
     * @param voter Dirección del votante autorizado
     */
    event VoterAuthorized(address indexed voter);

    /**
     * @dev Emitido cuando se cambia la fase electoral
     * @param newPhase Nueva fase electoral
     */
    event ElectionPhaseChanged(ElectionPhase newPhase);

    /**
     * @dev Emitido cuando se emite un voto
     * @param voter Dirección del votante
     * @param candidateId ID del candidato votado
     */
    event VoteCast(address indexed voter, uint256 indexed candidateId);

    /**
     * @dev Emitido cuando se declara el ganador
     * @param winnerId ID del candidato ganador
     * @param winnerName Nombre del ganador
     * @param totalVotes Total de votos recibidos
     */
    event WinnerDeclared(
        uint256 indexed winnerId,
        string winnerName,
        uint256 totalVotes
    );

    // ==================== ENUMS ====================

    /**
     * @dev Estados del ciclo electoral
     */
    enum ElectionPhase {
        Preparation, // Fase de preparación y registro
        Voting, // Período de votación activa
        Finalized // Elección finalizada
    }

    // ==================== ESTRUCTURAS ====================

    /**
     * @dev Estructura para representar un candidato
     */
    struct Candidate {
        uint256 id; // ID único del candidato
        string name; // Nombre del candidato
        uint256 voteCount; // Número de votos recibidos
        bool exists; // Flag para verificar existencia
    }

    /**
     * @dev Estructura para representar un votante
     */
    struct Voter {
        bool isAuthorized; // Si está autorizado para votar
        bool hasVoted; // Si ya ha emitido su voto
        uint256 votedFor; // ID del candidato por quien votó
    }

    // ==================== VARIABLES DE ESTADO ====================

    /// @dev Administrador electoral (quien despliega el contrato)
    address public admin;

    /// @dev Fase actual de la elección
    ElectionPhase public currentPhase;

    /// @dev Contador para IDs únicos de candidatos
    uint256 public candidateCount;

    /// @dev Total de votos emitidos
    uint256 public totalVotes;

    /// @dev Mapping de candidatos por ID
    mapping(uint256 => Candidate) public candidates;

    /// @dev Array de IDs de candidatos para iteración
    uint256[] public candidateIds;

    /// @dev Mapping de votantes por dirección
    mapping(address => Voter) public voters;

    /// @dev Array de direcciones de votantes autorizados
    address[] public authorizedVoters;

    /// @dev ID del candidato ganador (solo válido después de finalizar)
    uint256 public winnerId;

    // ==================== MODIFICADORES ====================

    /**
     * @dev Modificador que restringe acceso solo al administrador
     */
    modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Solo el administrador puede ejecutar esta funcion"
        );
        _;
    }

    /**
     * @dev Modificador que verifica la fase actual de la elección
     * @param _phase Fase requerida
     */
    modifier onlyInPhase(ElectionPhase _phase) {
        require(
            currentPhase == _phase,
            "Esta accion no esta permitida en la fase actual"
        );
        _;
    }

    /**
     * @dev Modificador que verifica que el votante esté autorizado
     */
    modifier onlyAuthorizedVoter() {
        require(
            voters[msg.sender].isAuthorized,
            "No estas autorizado para votar"
        );
        _;
    }

    /**
     * @dev Modificador que verifica que el votante no haya votado ya
     */
    modifier hasNotVoted() {
        require(!voters[msg.sender].hasVoted, "Ya has emitido tu voto");
        _;
    }

    /**
     * @dev Modificador que verifica que el candidato existe
     * @param _candidateId ID del candidato a verificar
     */
    modifier candidateExists(uint256 _candidateId) {
        require(candidates[_candidateId].exists, "El candidato no existe");
        _;
    }

    // ==================== CONSTRUCTOR ====================

    /**
     * @dev Constructor que inicializa el contrato
     * El deployer se convierte automáticamente en el administrador
     */
    constructor() {
        admin = msg.sender;
        currentPhase = ElectionPhase.Preparation;
        candidateCount = 0;
        totalVotes = 0;
        winnerId = 0;

        emit ElectionPhaseChanged(ElectionPhase.Preparation);
    }

    // ==================== FUNCIONES DE ADMINISTRACIÓN ====================

    /**
     * @dev Añade un nuevo candidato a la elección
     * @param _name Nombre del candidato
     * Solo disponible en fase de Preparación
     */
    function addCandidate(
        string memory _name
    ) external onlyAdmin onlyInPhase(ElectionPhase.Preparation) {
        require(
            bytes(_name).length > 0,
            "El nombre del candidato no puede estar vacio"
        );

        candidateCount++;

        candidates[candidateCount] = Candidate({
            id: candidateCount,
            name: _name,
            voteCount: 0,
            exists: true
        });

        candidateIds.push(candidateCount);

        emit CandidateAdded(candidateCount, _name);
    }

    /**
     * @dev Autoriza a un votante para participar en la elección
     * @param _voter Dirección del votante a autorizar
     * Solo disponible en fase de Preparación
     */
    function authorizeVoter(
        address _voter
    ) external onlyAdmin onlyInPhase(ElectionPhase.Preparation) {
        require(_voter != address(0), "Direccion de votante invalida");
        require(!voters[_voter].isAuthorized, "El votante ya esta autorizado");

        voters[_voter] = Voter({
            isAuthorized: true,
            hasVoted: false,
            votedFor: 0
        });

        authorizedVoters.push(_voter);

        emit VoterAuthorized(_voter);
    }

    /**
     * @dev Autoriza múltiples votantes de una vez
     * @param _voters Array de direcciones de votantes a autorizar
     * Solo disponible en fase de Preparación
     */
    function authorizeMultipleVoters(
        address[] memory _voters
    ) external onlyAdmin onlyInPhase(ElectionPhase.Preparation) {
        for (uint256 i = 0; i < _voters.length; i++) {
            if (_voters[i] != address(0) && !voters[_voters[i]].isAuthorized) {
                voters[_voters[i]] = Voter({
                    isAuthorized: true,
                    hasVoted: false,
                    votedFor: 0
                });

                authorizedVoters.push(_voters[i]);
                emit VoterAuthorized(_voters[i]);
            }
        }
    }

    /**
     * @dev Inicia el período de votación
     * Solo disponible en fase de Preparación
     * Requiere al menos un candidato y un votante autorizado
     */
    function startVoting()
        external
        onlyAdmin
        onlyInPhase(ElectionPhase.Preparation)
    {
        require(candidateCount > 0, "Debe haber al menos un candidato");
        require(
            authorizedVoters.length > 0,
            "Debe haber al menos un votante autorizado"
        );

        currentPhase = ElectionPhase.Voting;
        emit ElectionPhaseChanged(ElectionPhase.Voting);
    }

    /**
     * @dev Finaliza la elección y declara el ganador
     * Solo disponible en fase de Votación
     */
    function finalizeElection()
        external
        onlyAdmin
        onlyInPhase(ElectionPhase.Voting)
    {
        currentPhase = ElectionPhase.Finalized;

        // Determinar el ganador
        uint256 maxVotes = 0;
        uint256 winnerCandidateId = 0;

        for (uint256 i = 0; i < candidateIds.length; i++) {
            uint256 candidateId = candidateIds[i];
            if (candidates[candidateId].voteCount > maxVotes) {
                maxVotes = candidates[candidateId].voteCount;
                winnerCandidateId = candidateId;
            }
        }

        winnerId = winnerCandidateId;

        emit ElectionPhaseChanged(ElectionPhase.Finalized);

        if (winnerId > 0) {
            emit WinnerDeclared(
                winnerId,
                candidates[winnerId].name,
                candidates[winnerId].voteCount
            );
        }
    }

    // ==================== FUNCIONES DE VOTACIÓN ====================

    /**
     * @dev Permite a un votante autorizado emitir su voto
     * @param _candidateId ID del candidato por quien votar
     * Solo disponible en fase de Votación
     */
    function vote(
        uint256 _candidateId
    )
        external
        onlyInPhase(ElectionPhase.Voting)
        onlyAuthorizedVoter
        hasNotVoted
        candidateExists(_candidateId)
    {
        // Marcar al votante como que ya votó
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedFor = _candidateId;

        // Incrementar el contador de votos del candidato
        candidates[_candidateId].voteCount++;

        // Incrementar el total de votos
        totalVotes++;

        emit VoteCast(msg.sender, _candidateId);
    }

    // ==================== FUNCIONES DE CONSULTA ====================

    /**
     * @dev Obtiene información de un candidato
     * @param _candidateId ID del candidato
     * @return id ID del candidato
     * @return name Nombre del candidato
     * @return voteCount Número de votos recibidos
     */
    function getCandidate(
        uint256 _candidateId
    )
        external
        view
        candidateExists(_candidateId)
        returns (uint256 id, string memory name, uint256 voteCount)
    {
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }

    /**
     * @dev Obtiene todos los candidatos
     * @return candidateData Array con información de todos los candidatos
     */
    function getAllCandidates()
        external
        view
        returns (Candidate[] memory candidateData)
    {
        candidateData = new Candidate[](candidateIds.length);

        for (uint256 i = 0; i < candidateIds.length; i++) {
            candidateData[i] = candidates[candidateIds[i]];
        }

        return candidateData;
    }

    /**
     * @dev Obtiene información del votante
     * @param _voter Dirección del votante
     * @return isAuthorized Si está autorizado
     * @return hasVoted Si ya votó
     * @return votedFor ID del candidato por quien votó (0 si no ha votado)
     */
    function getVoterInfo(
        address _voter
    )
        external
        view
        returns (bool isAuthorized, bool hasVoted, uint256 votedFor)
    {
        Voter memory voter = voters[_voter];
        return (voter.isAuthorized, voter.hasVoted, voter.votedFor);
    }

    /**
     * @dev Obtiene el ganador de la elección
     * @return winnerId ID del candidato ganador
     * @return winnerName Nombre del ganador
     * @return winnerVotes Votos del ganador
     * Solo disponible después de finalizar la elección
     */
    function getWinner()
        external
        view
        onlyInPhase(ElectionPhase.Finalized)
        returns (uint256, string memory, uint256)
    {
        require(winnerId > 0, "No hay ganador declarado");

        Candidate memory winner = candidates[winnerId];
        return (winner.id, winner.name, winner.voteCount);
    }

    /**
     * @dev Obtiene estadísticas generales de la elección
     * @return phase Fase actual
     * @return totalCandidates Total de candidatos
     * @return totalAuthorizedVoters Total de votantes autorizados
     * @return totalVotesCast Total de votos emitidos
     */
    function getElectionStats()
        external
        view
        returns (
            ElectionPhase phase,
            uint256 totalCandidates,
            uint256 totalAuthorizedVoters,
            uint256 totalVotesCast
        )
    {
        return (
            currentPhase,
            candidateCount,
            authorizedVoters.length,
            totalVotes
        );
    }

    /**
     * @dev Obtiene la lista de IDs de todos los candidatos
     * @return Array con los IDs de los candidatos
     */
    function getCandidateIds() external view returns (uint256[] memory) {
        return candidateIds;
    }

    /**
     * @dev Obtiene la lista de votantes autorizados
     * @return Array con las direcciones de los votantes autorizados
     */
    function getAuthorizedVoters() external view returns (address[] memory) {
        return authorizedVoters;
    }

    /**
     * @dev Verifica si una dirección está autorizada para votar
     * @param _voter Dirección a verificar
     * @return true si está autorizada, false si no
     */
    function isAuthorizedVoter(address _voter) external view returns (bool) {
        return voters[_voter].isAuthorized;
    }

    /**
     * @dev Verifica si una dirección ya ha votado
     * @param _voter Dirección a verificar
     * @return true si ya votó, false si no
     */
    function hasVoterVoted(address _voter) external view returns (bool) {
        return voters[_voter].hasVoted;
    }
}

