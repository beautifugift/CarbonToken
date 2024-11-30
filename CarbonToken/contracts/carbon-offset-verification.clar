;; Carbon Offset Verification Smart Contract

;; Define constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))

;; Define data structures
(define-map certifications
  { project-id: uint }
  { 
    certifier: (string-ascii 64),
    certification-date: uint,
    expiration-date: uint
  }
)

(define-map carbon-credits
  { credit-id: uint }
  {
    project-id: uint,
    amount: uint,
    issuance-date: uint,
    retirement-date: (optional uint)
  }
)

(define-map project-performance
  { project-id: uint }
  { 
    last-update: uint,
    performance-score: uint
  }
)

;; Define public functions

;; Add or update certification
(define-public (add-certification (project-id uint) (certifier (string-ascii 64)) (certification-date uint) (expiration-date uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set certifications { project-id: project-id }
                 { 
                   certifier: certifier,
                   certification-date: certification-date,
                   expiration-date: expiration-date
                 }))
  )
)

;; Issue new carbon credits
(define-public (issue-carbon-credits (credit-id uint) (project-id uint) (amount uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set carbon-credits { credit-id: credit-id }
                 {
                   project-id: project-id,
                   amount: amount,
                   issuance-date: block-height,
                   retirement-date: none
                 }))
  )
)

;; Retire carbon credits
(define-public (retire-carbon-credits (credit-id uint))
  (let ((credit (unwrap! (map-get? carbon-credits { credit-id: credit-id }) err-not-found)))
    (ok (map-set carbon-credits { credit-id: credit-id }
                 (merge credit { retirement-date: (some block-height) })))
  )
)

;; Update project performance
(define-public (update-project-performance (project-id uint) (performance-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set project-performance { project-id: project-id }
                 { 
                   last-update: block-height,
                   performance-score: performance-score
                 }))
  )
)

;; Read-only functions

(define-read-only (get-certification (project-id uint))
  (map-get? certifications { project-id: project-id })
)

(define-read-only (get-carbon-credit (credit-id uint))
  (map-get? carbon-credits { credit-id: credit-id })
)

(define-read-only (get-project-performance (project-id uint))
  (map-get? project-performance { project-id: project-id })
)