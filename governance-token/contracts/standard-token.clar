;; Title: Advanced Fungible Token (AFT) for Stacks smart contract
;; Description: A robust token implementation with advanced features

;; Error Constants
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_TOKEN_OWNER (err u101))
(define-constant ERR_INSUFFICIENT_BALANCE (err u102))
(define-constant ERR_INVALID_AMOUNT (err u103))
(define-constant ERR_BLACKLISTED (err u104))
(define-constant ERR_CONTRACT_PAUSED (err u105))
(define-constant ERR_INVALID_RECIPIENT (err u106))
(define-constant ERR_ZERO_ADDRESS (err u107))
(define-constant ERR_INVALID_TOKEN_ID (err u108))
(define-constant ERR_UNAUTHORIZED_ACCESS (err u109))
(define-constant ERR_INVALID_INPUT (err u110))

;; Define response types
(define-constant ERR_TRANSFER (err u200))

;; Constants
(define-constant TOKEN_CONTRACT_OWNER tx-sender)

;; Data Variables
(define-data-var token-total-supply uint u0)
(define-data-var token-display-name (string-ascii 32) "Example Token")
(define-data-var token-trading-symbol (string-ascii 10) "EXT")
(define-data-var token-decimal-places uint u6)
(define-data-var contract-paused-state bool false)

;; Data Maps
(define-map token-holder-balances principal uint)
(define-map token-spending-allowances {token-owner: principal, authorized-spender: principal} uint)
(define-map blacklisted-addresses principal bool)
(define-map token-metadata-records {token-identifier: uint} {
    token-name: (string-ascii 64), 
    token-description: (string-ascii 256), 
    token-uri: (string-utf8 256)
})

;; Private Functions
(define-private (is-token-contract-owner)
    (is-eq tx-sender TOKEN_CONTRACT_OWNER))

(define-private (is-address-blacklisted (wallet-address principal))
    (default-to false (map-get? blacklisted-addresses wallet-address)))

(define-private (validate-token-transfer (sender-address principal) (transfer-amount uint))
    (and
        (not (is-address-blacklisted sender-address))
        (>= (default-to u0 (map-get? token-holder-balances sender-address)) transfer-amount)
        (> transfer-amount u0)))

(define-private (validate-string-ascii (input (string-ascii 256)))
    (is-eq (len input) (len (unwrap-panic (as-max-len? input u256)))))

(define-private (validate-string-utf8 (input (string-utf8 256)))
    (is-eq (len input) (len (unwrap-panic (as-max-len? input u256)))))

;; Read-Only Functions
(define-read-only (get-token-name)
    (ok (var-get token-display-name)))

(define-read-only (get-token-symbol)
    (ok (var-get token-trading-symbol)))

(define-read-only (get-token-decimals)
    (ok (var-get token-decimal-places)))

(define-read-only (get-token-total-supply)
    (ok (var-get token-total-supply)))

(define-read-only (get-holder-balance (wallet-address principal))
    (ok (default-to u0 (map-get? token-holder-balances wallet-address))))

(define-read-only (get-spending-allowance (token-owner principal) (authorized-spender principal))
    (ok (default-to u0 (map-get? token-spending-allowances {token-owner: token-owner, authorized-spender: authorized-spender}))))

(define-read-only (get-address-blacklist-status (wallet-address principal))
    (ok (default-to false (map-get? blacklisted-addresses wallet-address))))

;; Public Functions
(define-public (initialize-token (display-name (string-ascii 32)) (trading-symbol (string-ascii 10)) (decimal-places uint))
    (begin
        (asserts! (is-token-contract-owner) ERR_OWNER_ONLY)
        (asserts! (validate-string-ascii display-name) ERR_INVALID_INPUT)
        (asserts! (validate-string-ascii trading-symbol) ERR_INVALID_INPUT)
        (asserts! (<= decimal-places u255) ERR_INVALID_INPUT)
        (var-set token-display-name display-name)
        (var-set token-trading-symbol trading-symbol)
        (var-set token-decimal-places decimal-places)
        (ok true)))

(define-public (transfer-tokens (recipient-address principal) (transfer-amount uint))
    (let ((sender-address tx-sender))
        (begin
            (asserts! (validate-token-transfer sender-address transfer-amount) ERR_INSUFFICIENT_BALANCE)
            (asserts! (not (is-address-blacklisted recipient-address)) ERR_BLACKLISTED)
            (asserts! (not (var-get contract-paused-state)) ERR_CONTRACT_PAUSED)
            (process-token-transfer sender-address recipient-address transfer-amount))))

(define-public (transfer-tokens-from (owner-address principal) (recipient-address principal) (transfer-amount uint))
    (let ((spender-address tx-sender))
        (begin
            (asserts! (validate-token-transfer owner-address transfer-amount) ERR_INSUFFICIENT_BALANCE)
            (asserts! (not (is-address-blacklisted recipient-address)) ERR_BLACKLISTED)
            (asserts! (not (var-get contract-paused-state)) ERR_CONTRACT_PAUSED)
            (asserts! (>= (default-to u0 (map-get? token-spending-allowances {token-owner: owner-address, authorized-spender: spender-address})) transfer-amount) ERR_INSUFFICIENT_BALANCE)
            (match (decrease-spending-allowance owner-address spender-address transfer-amount)
                success (if success
                    (process-token-transfer owner-address recipient-address transfer-amount)
                    ERR_TRANSFER)
                error (err error)))))

(define-public (approve-token-spender (authorized-spender principal) (approved-amount uint))
    (begin
        (asserts! (not (is-address-blacklisted tx-sender)) ERR_BLACKLISTED)
        (asserts! (not (is-address-blacklisted authorized-spender)) ERR_BLACKLISTED)
        (asserts! (not (var-get contract-paused-state)) ERR_CONTRACT_PAUSED)
        (asserts! (not (is-eq tx-sender authorized-spender)) ERR_UNAUTHORIZED_ACCESS)
        (asserts! (or (is-eq approved-amount u0) (> approved-amount u0)) ERR_INVALID_AMOUNT)
        (ok (map-set token-spending-allowances {token-owner: tx-sender, authorized-spender: authorized-spender} approved-amount))))

;; Admin Functions
(define-public (mint-new-tokens (recipient-address principal) (mint-amount uint))
    (begin
        (asserts! (is-token-contract-owner) ERR_OWNER_ONLY)
        (asserts! (not (is-address-blacklisted recipient-address)) ERR_BLACKLISTED)
        (asserts! (> mint-amount u0) ERR_INVALID_AMOUNT)
        (process-token-mint recipient-address mint-amount)))

(define-public (burn-existing-tokens (burn-amount uint))
    (begin
        (asserts! (validate-token-transfer tx-sender burn-amount) ERR_INSUFFICIENT_BALANCE)
        (asserts! (not (var-get contract-paused-state)) ERR_CONTRACT_PAUSED)
        (process-token-burn tx-sender burn-amount)))

(define-public (add-address-to-blacklist (target-address principal))
    (begin
        (asserts! (is-token-contract-owner) ERR_OWNER_ONLY)
        (asserts! (not (is-eq target-address TOKEN_CONTRACT_OWNER)) ERR_UNAUTHORIZED_ACCESS)
        (ok (map-set blacklisted-addresses target-address true))))

(define-public (remove-address-from-blacklist (target-address principal))
    (begin
        (asserts! (is-token-contract-owner) ERR_OWNER_ONLY)
        (asserts! (is-some (map-get? blacklisted-addresses target-address)) ERR_INVALID_INPUT)
        (ok (map-delete blacklisted-addresses target-address))))

(define-public (set-token-metadata (token-id uint) (metadata-name (string-ascii 64)) (metadata-description (string-ascii 256)) (metadata-uri (string-utf8 256)))
    (begin
        (asserts! (is-token-contract-owner) ERR_OWNER_ONLY)
        (asserts! (validate-string-ascii metadata-name) ERR_INVALID_INPUT)
        (asserts! (validate-string-ascii metadata-description) ERR_INVALID_INPUT)
        (asserts! (validate-string-utf8 metadata-uri) ERR_INVALID_INPUT)
        (asserts! (> token-id u0) ERR_INVALID_TOKEN_ID)
        (ok (map-set token-metadata-records 
            {token-identifier: token-id} 
            {token-name: metadata-name, token-description: metadata-description, token-uri: metadata-uri}))))

;; Helper Functions
(define-private (process-token-transfer (sender-address principal) (recipient-address principal) (transfer-amount uint))
    (let ((sender-current-balance (default-to u0 (map-get? token-holder-balances sender-address)))
          (recipient-current-balance (default-to u0 (map-get? token-holder-balances recipient-address))))
        (begin
            (map-set token-holder-balances sender-address (- sender-current-balance transfer-amount))
            (map-set token-holder-balances recipient-address (+ recipient-current-balance transfer-amount))
            (ok true))))

(define-private (process-token-mint (recipient-address principal) (mint-amount uint))
    (let ((recipient-current-balance (default-to u0 (map-get? token-holder-balances recipient-address)))
          (current-total-supply (var-get token-total-supply)))
        (begin
            (map-set token-holder-balances recipient-address (+ recipient-current-balance mint-amount))
            (var-set token-total-supply (+ current-total-supply mint-amount))
            (ok true))))

(define-private (process-token-burn (owner-address principal) (burn-amount uint))
    (let ((owner-current-balance (default-to u0 (map-get? token-holder-balances owner-address)))
          (current-total-supply (var-get token-total-supply)))
        (begin
            (map-set token-holder-balances owner-address (- owner-current-balance burn-amount))
            (var-set token-total-supply (- current-total-supply burn-amount))
            (ok true))))

(define-private (decrease-spending-allowance (token-owner principal) (authorized-spender principal) (decrease-amount uint))
    (let ((current-allowance (default-to u0 (map-get? token-spending-allowances 
            {token-owner: token-owner, authorized-spender: authorized-spender}))))
        (begin 
            (asserts! (>= current-allowance decrease-amount) ERR_INSUFFICIENT_BALANCE)
            (map-set token-spending-allowances 
                {token-owner: token-owner, authorized-spender: authorized-spender} 
                (- current-allowance decrease-amount))
            (ok true))))