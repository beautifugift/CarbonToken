;; Carbon Offset Tracking and Reporting System

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_INVALID_AMOUNT (err u101))
(define-constant ERR_INSUFFICIENT_CREDITS (err u102))
(define-constant ERR_MAX_ACCOUNTS_REACHED (err u103))

;; Data maps
(define-map credits principal uint)
(define-map retired-credits principal uint)
(define-map activity-credits {activity: (string-ascii 64), business: principal} uint)

;; Data variable for tracking registered accounts
(define-data-var accounts (list 1000 principal) (list))

;; Public functions

;; Register an account
(define-public (register-account)
  (let ((current-accounts (var-get accounts)))
    (if (is-some (index-of current-accounts tx-sender))
      (ok true) ;; Account already registered
      (if (< (len current-accounts) u1000)
        (begin
          (var-set accounts (unwrap-panic (as-max-len? (append current-accounts tx-sender) u1000)))
          (ok true))
        ERR_MAX_ACCOUNTS_REACHED))))

;; Claim carbon credits
(define-public (claim-credits (amount uint))
  (let ((current-balance (default-to u0 (map-get? credits tx-sender))))
    (map-set credits tx-sender (+ current-balance amount))
    (ok amount)))

;; Retire carbon credits
(define-public (retire-credits (amount uint))
  (let ((current-balance (default-to u0 (map-get? credits tx-sender)))
        (current-retired (default-to u0 (map-get? retired-credits tx-sender))))
    (if (<= amount current-balance)
      (begin
        (map-set credits tx-sender (- current-balance amount))
        (map-set retired-credits tx-sender (+ current-retired amount))
        (ok amount))
      ERR_INSUFFICIENT_CREDITS)))

;; Associate credits with an activity and business
(define-public (associate-credits (activity (string-ascii 64)) (business principal) (amount uint))
  (let ((current-balance (default-to u0 (map-get? credits tx-sender)))
        (current-associated (default-to u0 (map-get? activity-credits {activity: activity, business: business}))))
    (if (<= amount current-balance)
      (begin
        (map-set credits tx-sender (- current-balance amount))
        (map-set activity-credits {activity: activity, business: business} (+ current-associated amount))
        (ok amount))
      ERR_INSUFFICIENT_CREDITS)))

;; Read-only functions

;; Get credit balance for a user
(define-read-only (get-credit-balance (user principal))
  (default-to u0 (map-get? credits user)))

;; Get retired credit balance for a user
(define-read-only (get-retired-credit-balance (user principal))
  (default-to u0 (map-get? retired-credits user)))

;; Get credits associated with an activity and business
(define-read-only (get-activity-credits (activity (string-ascii 64)) (business principal))
  (default-to u0 (map-get? activity-credits {activity: activity, business: business})))

;; Get total retired credits (for public ledger)
(define-read-only (get-total-retired-credits)
  (fold + 
    (map get-retired-credit-balance 
      (unwrap-panic (list-accounts)))
    u0))

;; Private functions

;; Helper function to get all accounts
(define-private (list-accounts)
  (ok (var-get accounts)))