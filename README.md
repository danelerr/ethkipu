# Sistema Electoral Descentralizado

## Descripción General

Este proyecto implementa un **Sistema de Votación Electoral Descentralizada**. El contrato inteligente `ElectoralSystem` gestiona un proceso electoral completo con fases claramente definidas, garantizando transparencia, seguridad y auditabilidad.

## Características Principales

### Gestión de Fases Electorales
- **Preparación**: Registro de candidatos y autorización de votantes
- **Votación**: Período activo donde los votantes emiten sus sufragios
- **Finalizada**: Consulta de resultados y ganador

### Roles y Permisos
- **Administrador Electoral (admin)**: Controla el flujo electoral (quien despliega el contrato)
- **Votantes Autorizados**: Solo pueden votar direcciones previamente autorizadas
- **Público**: Cualquiera puede consultar candidatos y resultados finales

### Seguridad Implementada
- Un voto por votante autorizado
- Imposible votar por candidatos inexistentes
- Control de fases para prevenir acciones en momentos incorrectos
- Solo el administrador puede gestionar la elección

## Arquitectura del Contrato

### Estructuras de Datos

```solidity
// Fases del ciclo electoral
enum ElectionPhase {
    Preparation,    // Preparación y registro
    Voting,        // Votación activa
    Finalized      // Elección finalizada
}

// Estructura del candidato
struct Candidate {
    uint256 id;        // ID único
    string name;       // Nombre
    uint256 voteCount; // Votos recibidos
    bool exists;       // Flag de existencia
}

// Estructura del votante
struct Voter {
    bool isAuthorized; // Autorización
    bool hasVoted;     // Estado de voto
    uint256 votedFor;  // Candidato votado
}
```

### Modificadores de Seguridad

- `onlyAdmin`: Restringe acceso al administrador
- `onlyInPhase`: Verifica la fase actual
- `onlyAuthorizedVoter`: Solo votantes autorizados
- `hasNotVoted`: Previene doble votación
- `candidateExists`: Valida existencia del candidato

### Eventos

- `CandidateAdded`: Nuevo candidato registrado
- `VoterAuthorized`: Votante autorizado
- `ElectionPhaseChanged`: Cambio de fase
- `VoteCast`: Voto emitido
- `WinnerDeclared`: Ganador declarado

## Funcionalidades

### Funciones del Administrador

#### `addCandidate(string _name)`
- Añade un nuevo candidato
- Solo en fase de Preparación
- Requiere nombre no vacío

#### `authorizeVoter(address _voter)`
- Autoriza a un votante individual
- Solo en fase de Preparación
- Valida dirección única

#### `authorizeMultipleVoters(address[] _voters)`
- Autoriza múltiples votantes en lote
- Optimiza gas para muchos votantes
- Ignora direcciones inválidas o duplicadas

#### `startVoting()`
- Inicia el período de votación
- Requiere al menos 1 candidato y 1 votante
- Bloquea modificaciones posteriores

#### `finalizeElection()`
- Finaliza la elección
- Calcula y declara el ganador
- Permite consultas de resultados

### 🗳️ Funciones de Votación

#### `vote(uint256 _candidateId)`
- Emite un voto por un candidato
- Solo votantes autorizados
- Solo en fase de Votación
- Un voto por votante

### Funciones de Consulta

#### `getCandidate(uint256 _candidateId)`
- Obtiene información de un candidato específico

#### `getAllCandidates()`
- Lista todos los candidatos con sus votos

#### `getVoterInfo(address _voter)`
- Consulta estado de un votante

#### `getWinner()`
- Obtiene información del ganador (solo después de finalizar)

#### `getElectionStats()`
- Estadísticas generales de la elección

## Flujo de Uso

### 1. Despliegue del Contrato
```solidity
// El deployer se convierte automáticamente en admin
ElectoralSystem election = new ElectoralSystem();
```

### 2. Fase de Preparación
```solidity
// Añadir candidatos
election.addCandidate("Tuto Quiroga");
election.addCandidate("Samuel Doria Medina");
election.addCandidate("Manfred Reyes");

// Autorizar votantes
address[] memory voters = [0x123, 0x456, 0x789];
election.authorizeMultipleVoters(voters);
```

### 3. Iniciar Votación
```solidity
// Cambiar a fase de votación
election.startVoting();
```

### 4. Proceso de Votación
```solidity
// Los votantes emiten sus votos
election.vote(1); // Voto por candidato ID 1
```

### 5. Finalización
```solidity
// Finalizar elección y declarar ganador
election.finalizeElection();

// Consultar ganador
(uint256 winnerId, string memory name, uint256 votes) = election.getWinner();
```

## Pasos para desplegar

1. **Abrir Remix IDE**
   - Ir a [https://remix.ethereum.org/](https://remix.ethereum.org/)

2. **Crear el Archivo**
   - Crear nuevo archivo `ElectoralSystem.sol`
   - Copiar el código del contrato

3. **Compilar**
   - Seleccionar Solidity ^0.8.20
   - Compilar el contrato

4. **Desplegar en Sepolia**
   - Conectar MetaMask a Sepolia
   - Desplegar desde la pestaña "Deploy & Run"
   - Copiar dirección del contrato desplegado

5. **Verificar en Etherscan**
   - Ir a Sepolia Etherscan
   - Pegar dirección del contrato
   - Usar función "Verify and Publish"


## Optimizaciones de Gas

- Uso de `mapping` para búsquedas O(1)
- Arrays separados para iteración eficiente
- Batch operations para múltiples votantes
- Events para notificaciones off-chain