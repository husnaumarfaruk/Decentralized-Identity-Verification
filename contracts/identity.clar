;; Identity Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))

(define-map identities
  { address: principal }
  {
    kyc-status: (string-ascii 20),
    credit-score: uint,
    last-updated: uint
  }
)

(define-map authorized-verifiers
  { address: principal }
  { status: bool }
)

(define-public (register-identity)
  (let
    ((caller tx-sender))
    (asserts! (is-none (map-get? identities { address: caller })) (err u403))
    (ok (map-set identities
      { address: caller }
      {
        kyc-status: "unverified",
        credit-score: u0,
        last-updated: block-height
      }
    ))
  )
)

(define-public (update-kyc-status (address principal) (status (string-ascii 20)))
  (let
    ((caller tx-sender))
    (asserts! (is-authorized caller) (err u401))
    (asserts! (is-some (map-get? identities { address: address })) (err u404))
    (ok (map-set identities
      { address: address }
      (merge (unwrap-panic (map-get? identities { address: address }))
        {
          kyc-status: status,
          last-updated: block-height
        }
      )
    ))
  )
)

(define-public (update-credit-score (address principal) (score uint))
  (let
    ((caller tx-sender))
    (asserts! (is-authorized caller) (err u401))
    (asserts! (is-some (map-get? identities { address: address })) (err u404))
    (ok (map-set identities
      { address: address }
      (merge (unwrap-panic (map-get? identities { address: address }))
        {
          credit-score: score,
          last-updated: block-height
        }
      )
    ))
  )
)

(define-public (add-authorized-verifier (verifier principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller contract-owner) (err u401))
    (ok (map-set authorized-verifiers
      { address: verifier }
      { status: true }
    ))
  )
)

(define-public (remove-authorized-verifier (verifier principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller contract-owner) (err u401))
    (ok (map-delete authorized-verifiers { address: verifier }))
  )
)

(define-read-only (get-identity (address principal))
  (map-get? identities { address: address })
)

(define-read-only (is-authorized (address principal))
  (default-to false (get status (map-get? authorized-verifiers { address: address })))
)

