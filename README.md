# DeedChainOwnership

## Overview
DeedChainOwnership is a smart contract designed to manage real-world asset ownership records securely on the blockchain. It provides functionalities for ownership tracking, transfer validation, and history logging, ensuring a transparent and immutable record of asset ownership.

## Features
- **Secure Ownership Tracking**: Maintains a registry of asset (deed) ownership.
- **Transfer Validation**: Ensures that only the rightful owner can transfer ownership.
- **History Logging**: Records all ownership transfers for traceability.
- **Read-Only Queries**: Enables verification of ownership, transfer history, and deed status.

## Smart Contract Details

### Constants
- `ERR-NOT-AUTHORIZED (err u1)`: Error code for unauthorized access.
- `ERR-INVALID-DEED (err u2)`: Error code for invalid deed ID.
- `ERR-ALREADY-REGISTERED (err u3)`: Error code for duplicate deed registration.
- `ERR-NOT-OWNER (err u4)`: Error code for unauthorized transfers.
- `ERR-INVALID-TRANSFER (err u5)`: Error code for invalid transfer operations.
- `CONTRACT-OWNER`: Set as the transaction sender (`tx-sender`).
- `STATUS-ACTIVE`: Default status of a registered deed.

### Data Structures

#### Deeds Map
Stores ownership and metadata about registered deeds.
```clojure
(define-map deeds
    { deed-id: (string-utf8 36) }
    {
        owner: principal,
        description: (string-utf8 256),
        registration-date: uint,
        status: (string-ascii 6)
    }
)
```

#### Ownership History Map
Tracks all transfers of a deed.
```clojure
(define-map ownership-history
    { deed-id: (string-utf8 36), index: uint }
    {
        previous-owner: principal,
        new-owner: principal,
        transfer-date: uint,
        transaction-hash: (buff 32)
    }
)
```

#### Deed History Indexes Map
Stores the latest index for ownership history tracking.
```clojure
(define-map deed-history-indexes
    { deed-id: (string-utf8 36) }
    { current-index: uint }
)
```

## Functions

### Public Functions

#### `register-deed`
Registers a new deed with a unique ID and description.
```clojure
(define-public (register-deed (deed-id (string-utf8 36)) (description (string-utf8 256)))
```
- **Returns:**
  - `ERR-ALREADY-REGISTERED` if the deed ID already exists.
  - Stores the deed with the sender as the owner.

#### `transfer-deed`
Transfers ownership of a deed to a new owner.
```clojure
(define-public (transfer-deed (deed-id (string-utf8 36)) (new-owner principal))
```
- **Validations:**
  - Ensures the sender is the current owner.
  - Updates the owner and logs the transfer.

### Read-Only Functions

#### `get-deed-owner`
Retrieves the current owner of a deed.
```clojure
(define-read-only (get-deed-owner (deed-id (string-utf8 36)))
```

#### `get-deed-history`
Fetches the ownership transfer history of a deed.
```clojure
(define-read-only (get-deed-history (deed-id (string-utf8 36)))
```

#### `verify-deed-status`
Checks the status of a registered deed.
```clojure
(define-read-only (verify-deed-status (deed-id (string-utf8 36)))
```

## Security Considerations
- Only the current owner can transfer ownership.
- Prevents duplicate registration of deed IDs.
- Ensures transaction integrity by logging transfers immutably.

## License
This smart contract is open-source and provided under the MIT License.

