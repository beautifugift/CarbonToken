;; Carbon Credit NFT Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))

;; Define the NFT
(define-non-fungible-token carbon-credit uint)

;; Data Variables
(define-map token-metadata
  uint
  {
    project: (string-ascii 100),
    location: (string-ascii 50),
    verifier: (string-ascii 50),
    offset-amount: uint
  }
)

(define-data-var last-token-id uint u0)

;; Mint new carbon credit NFT
(define-public (mint-carbon-credit (project (string-ascii 100)) (location (string-ascii 50)) (verifier (string-ascii 50)) (offset-amount uint))
  (let
    (
      (token-id (+ (var-get last-token-id) u1))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (try! (nft-mint? carbon-credit token-id tx-sender))
    (map-set token-metadata token-id {project: project, location: location, verifier: verifier, offset-amount: offset-amount})
    (var-set last-token-id token-id)
    (ok token-id)
  )
)

;; Get token metadata
(define-read-only (get-token-metadata (token-id uint))
  (ok (map-get? token-metadata token-id))
)

;; Get token owner
(define-read-only (get-token-owner (token-id uint))
  (ok (nft-get-owner? carbon-credit token-id))
)

;; Transfer token
(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) err-not-token-owner)
    (nft-transfer? carbon-credit token-id sender recipient)
  )
)

;; Get last token ID
(define-read-only (get-last-token-id)
  (ok (var-get last-token-id))
)