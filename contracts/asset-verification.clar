;; Asset Verification Contract
;; Validates energy generation equipment

(define-data-var admin principal tx-sender)

;; Asset types
(define-constant SOLAR u1)
(define-constant WIND u2)
(define-constant HYDRO u3)
(define-constant BATTERY u4)

;; Asset status
(define-constant PENDING u0)
(define-constant VERIFIED u1)
(define-constant REJECTED u2)

;; Asset data structure
(define-map assets
  { asset-id: uint }
  {
    owner: principal,
    asset-type: uint,
    capacity: uint,
    location: (string-utf8 100),
    status: uint,
    verification-date: uint
  }
)

;; Asset counter
(define-data-var asset-counter uint u0)

;; Register a new asset
(define-public (register-asset (asset-type uint) (capacity uint) (location (string-utf8 100)))
  (let ((asset-id (+ (var-get asset-counter) u1)))
    (begin
      (asserts! (or (is-eq asset-type SOLAR)
                   (is-eq asset-type WIND)
                   (is-eq asset-type HYDRO)
                   (is-eq asset-type BATTERY)) (err u1))
      (asserts! (> capacity u0) (err u2))
      (map-set assets
        { asset-id: asset-id }
        {
          owner: tx-sender,
          asset-type: asset-type,
          capacity: capacity,
          location: location,
          status: PENDING,
          verification-date: u0
        }
      )
      (var-set asset-counter asset-id)
      (ok asset-id)
    )
  )
)

;; Verify an asset (admin only)
(define-public (verify-asset (asset-id uint))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err u3))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u4))
      (asserts! (is-eq (get status asset) PENDING) (err u5))
      (map-set assets
        { asset-id: asset-id }
        (merge asset {
          status: VERIFIED,
          verification-date: block-height
        })
      )
      (ok true)
    )
  )
)

;; Reject an asset (admin only)
(define-public (reject-asset (asset-id uint))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err u3))))
    (begin
      (asserts! (is-eq tx-sender (var-get admin)) (err u4))
      (asserts! (is-eq (get status asset) PENDING) (err u5))
      (map-set assets
        { asset-id: asset-id }
        (merge asset {
          status: REJECTED,
          verification-date: block-height
        })
      )
      (ok true)
    )
  )
)

;; Get asset details
(define-read-only (get-asset (asset-id uint))
  (map-get? assets { asset-id: asset-id })
)

;; Check if asset is verified
(define-read-only (is-asset-verified (asset-id uint))
  (match (map-get? assets { asset-id: asset-id })
    asset (is-eq (get status asset) VERIFIED)
    false
  )
)

;; Transfer asset ownership
(define-public (transfer-asset (asset-id uint) (new-owner principal))
  (let ((asset (unwrap! (map-get? assets { asset-id: asset-id }) (err u3))))
    (begin
      (asserts! (is-eq (get owner asset) tx-sender) (err u6))
      (map-set assets
        { asset-id: asset-id }
        (merge asset { owner: new-owner })
      )
      (ok true)
    )
  )
)

;; Set a new admin
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u4))
    (var-set admin new-admin)
    (ok true)
  )
)
