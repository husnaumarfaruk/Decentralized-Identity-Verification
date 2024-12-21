;; Financial Services Contract

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u404))
(define-constant err-unauthorized (err u401))
(define-constant err-insufficient-credit-score (err u402))

(define-map loan-applications
  { id: uint }
  {
    applicant: principal,
    amount: uint,
    status: (string-ascii 20),
    approved-by: (optional principal)
  }
)

(define-data-var application-id-nonce uint u0)

(define-public (apply-for-loan (amount uint))
  (let
    (
      (caller tx-sender)
      (application-id (var-get application-id-nonce))
    )
    (map-set loan-applications
      { id: application-id }
      {
        applicant: caller,
        amount: amount,
        status: "pending",
        approved-by: none
      }
    )
    (var-set application-id-nonce (+ application-id u1))
    (ok application-id)
  )
)

(define-public (approve-loan (application-id uint))
  (let
    (
      (caller tx-sender)
      (application (unwrap! (map-get? loan-applications { id: application-id }) (err u404)))
    )
    (asserts! (is-eq (get status application) "pending") (err u401))
    (ok (map-set loan-applications
      { id: application-id }
      (merge application
        {
          status: "approved",
          approved-by: (some caller)
        }
      )
    ))
  )
)

(define-read-only (get-loan-application (application-id uint))
  (map-get? loan-applications { id: application-id })
)

