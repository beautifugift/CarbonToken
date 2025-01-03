;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-credit-listing-failed (err u103))
(define-constant err-balance-setting-failed (err u104))
(define-constant err-update-credit-failed (err u105))
(define-constant err-update-balance-failed (err u106))

;; Define data variables
(define-data-var next-credit-id uint u0)
(define-data-var platform-fee uint u5) ;; 0.5% fee, represented as 5/1000

;; Define maps
(define-map credits
  { credit-id: uint }
  {
    owner: principal,
    project-type: (string-ascii 64),
    location: (string-ascii 64),
    verification-body: (string-ascii 64),
    total-supply: uint,
    available-supply: uint,
    price-per-unit: uint
  }
)

(define-map balances
  { owner: principal, credit-id: uint }
  { balance: uint }
)

;; Define functions

;; Function to list a new carbon credit
(define-public (list-credit (project-type (string-ascii 64)) (location (string-ascii 64)) (verification-body (string-ascii 64)) (total-supply uint) (price-per-unit uint))
  (let
    (
      (credit-id (var-get next-credit-id))
    )
    (asserts! (map-set credits
      { credit-id: credit-id }
      {
        owner: tx-sender,
        project-type: project-type,
        location: location,
        verification-body: verification-body,
        total-supply: total-supply,
        available-supply: total-supply,
        price-per-unit: price-per-unit
      }
    ) err-credit-listing-failed)
    (asserts! (map-set balances
      { owner: tx-sender, credit-id: credit-id }
      { balance: total-supply }
    ) err-balance-setting-failed)
    (var-set next-credit-id (+ credit-id u1))
    (ok credit-id)
  )
)

;; Function to buy carbon credits
(define-public (buy-credit (credit-id uint) (amount uint))
  (let
    (
      (credit (unwrap! (map-get? credits { credit-id: credit-id }) err-not-found))
      (total-price (* amount (get price-per-unit credit)))
      (fee (/ (* total-price (var-get platform-fee)) u1000))
    )
    (asserts! (<= amount (get available-supply credit)) err-insufficient-balance)
    (try! (stx-transfer? (+ total-price fee) tx-sender (get owner credit)))
    (try! (stx-transfer? fee (get owner credit) contract-owner))
    (asserts! (map-set credits
      { credit-id: credit-id }
      (merge credit { available-supply: (- (get available-supply credit) amount) })
    ) err-update-credit-failed)
    (asserts! (map-set balances
      { owner: tx-sender, credit-id: credit-id }
      { balance: (+ (default-to u0 (get balance (map-get? balances { owner: tx-sender, credit-id: credit-id }))) amount) }
    ) err-update-balance-failed)
    (ok true)
  )
)

;; Function to fractionalize credits (sell a portion of owned credits)
(define-public (fractionalize-credit (credit-id uint) (amount uint) (new-price-per-unit uint))
  (let
    (
      (balance (default-to u0 (get balance (map-get? balances { owner: tx-sender, credit-id: credit-id }))))
      (credit (unwrap! (map-get? credits { credit-id: credit-id }) err-not-found))
    )
    (asserts! (>= balance amount) err-insufficient-balance)
    (asserts! (map-set balances
      { owner: tx-sender, credit-id: credit-id }
      { balance: (- balance amount) }
    ) err-update-balance-failed)
    (asserts! (map-set credits
      { credit-id: credit-id }
      (merge credit
        {
          available-supply: (+ (get available-supply credit) amount),
          price-per-unit: new-price-per-unit
        }
      )
    ) err-update-credit-failed)
    (ok true)
  )
)

;; Function to get credit details (for search/filter functionality)
(define-read-only (get-credit (credit-id uint))
  (map-get? credits { credit-id: credit-id })
)

;; Function to update platform fee (owner only)
(define-public (set-platform-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set platform-fee new-fee))
  )
)