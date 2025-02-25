;; DeedChainOwnership
;; Smart contract for managing real-world asset ownership records
;; Implements secure ownership tracking, transfer validation, and history logging

;; Constants
(define-constant ERR-NOT-AUTHORIZED (err u1))
(define-constant ERR-INVALID-DEED (err u2))
(define-constant ERR-ALREADY-REGISTERED (err u3))
(define-constant ERR-NOT-OWNER (err u4))
(define-constant ERR-INVALID-TRANSFER (err u5))
(define-constant CONTRACT-OWNER tx-sender)
(define-constant STATUS-ACTIVE "active")

;; Data Maps
(define-map deeds
    { deed-id: (string-utf8 36) }
    {
        owner: principal,
        description: (string-utf8 256),
        registration-date: uint,
        status: (string-ascii 6)  ;; Changed to match "active" length
    }
)

(define-map ownership-history
    { deed-id: (string-utf8 36), index: uint }
    {
        previous-owner: principal,
        new-owner: principal,
        transfer-date: uint,
        transaction-hash: (buff 32)
    }
)

(define-map deed-history-indexes
    { deed-id: (string-utf8 36) }
    { current-index: uint }
)

;; Private Functions
(define-private (validate-deed-id (deed-id (string-utf8 36)))
    (let
        (
            (deed-exists (is-some (map-get? deeds { deed-id: deed-id })))
        )
        (if deed-exists
            (ok true)
            ERR-INVALID-DEED
        )
    )
)

(define-private (validate-ownership (deed-id (string-utf8 36)) (caller principal))
    (let
        (
            (deed-data (unwrap! (map-get? deeds { deed-id: deed-id }) ERR-INVALID-DEED))
        )
        (if (is-eq (get owner deed-data) caller)
            (ok true)
            ERR-NOT-OWNER
        )
    )
)

(define-private (record-transfer
    (deed-id (string-utf8 36))
    (previous-owner principal)
    (new-owner principal)
    (transaction-hash (buff 32)))
    (let
        (
            (current-index-data (default-to { current-index: u0 }
                (map-get? deed-history-indexes { deed-id: deed-id })))
            (new-index (+ (get current-index current-index-data) u1))
        )
        (begin
            (map-set ownership-history
                { deed-id: deed-id, index: new-index }
                {
                    previous-owner: previous-owner,
                    new-owner: new-owner,
                    transfer-date: block-height,
                    transaction-hash: transaction-hash
                }
            )
            (map-set deed-history-indexes
                { deed-id: deed-id }
                { current-index: new-index }
            )
            (ok new-index)
        )
    )
)

;; Public Functions
(define-public (register-deed 
    (deed-id (string-utf8 36))
    (description (string-utf8 256)))
    (let
        (
            (caller tx-sender)
            (deed-exists (is-some (map-get? deeds { deed-id: deed-id })))
        )
        (if deed-exists
            ERR-ALREADY-REGISTERED
            (begin
                (map-set deeds
                    { deed-id: deed-id }
                    {
                        owner: caller,
                        description: description,
                        registration-date: block-height,
                        status: STATUS-ACTIVE
                    }
                )
                (record-transfer deed-id CONTRACT-OWNER caller (hash160 1))
            )
        )
    )
)

(define-public (transfer-deed
    (deed-id (string-utf8 36))
    (new-owner principal))
    (let
        (
            (caller tx-sender)
            (ownership-validation (try! (validate-ownership deed-id caller)))
            (deed-data (unwrap! (map-get? deeds { deed-id: deed-id }) ERR-INVALID-DEED))
        )
        (begin
            (map-set deeds
                { deed-id: deed-id }
                (merge deed-data { owner: new-owner })
            )
            (record-transfer 
                deed-id 
                caller 
                new-owner 
                (hash160 block-height)
            )
        )
    )
)

;; Read-only Functions
(define-read-only (get-deed-owner (deed-id (string-utf8 36)))
    (let
        (
            (deed-data (map-get? deeds { deed-id: deed-id }))
        )
        (ok (get owner (unwrap! deed-data ERR-INVALID-DEED)))
    )
)

(define-read-only (get-deed-history (deed-id (string-utf8 36)))
    (let
        (
            (deed-validation (try! (validate-deed-id deed-id)))
            (history-index-data (unwrap! 
                (map-get? deed-history-indexes { deed-id: deed-id })
                ERR-INVALID-DEED))
            (current-index (get current-index history-index-data))
        )
        (ok {
            deed-id: deed-id,
            total-transfers: current-index,
            last-transfer: (map-get? ownership-history 
                { deed-id: deed-id, index: current-index })
        })
    )
)

(define-read-only (verify-deed-status (deed-id (string-utf8 36)))
    (let
        (
            (deed-data (map-get? deeds { deed-id: deed-id }))
        )
        (if (is-some deed-data)
            (ok (get status (unwrap! deed-data ERR-INVALID-DEED)))
            ERR-INVALID-DEED
        )
    )
)