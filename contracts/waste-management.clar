;; Waste Management Contract

(define-map waste-collections
  { collection-id: uint }
  {
    user: principal,
    waste-type: (string-ascii 20),
    amount: uint,
    timestamp: uint,
    verified: bool
  }
)

(define-map user-collections
  { user: principal }
  { collection-ids: (list 100 uint) }
)

(define-map user-total-waste
  { user: principal }
  { total-amount: uint }
)

(define-data-var collection-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_NOT_FOUND (err u404))

(define-read-only (get-waste-collection (collection-id uint))
  (map-get? waste-collections { collection-id: collection-id })
)

(define-read-only (get-user-collections (user principal))
  (map-get? user-collections { user: user })
)

(define-public (record-waste-collection (waste-type (string-ascii 20)) (amount uint))
  (let
    ((new-collection-id (+ (var-get collection-id-nonce) u1))
     (user-collection-list (default-to { collection-ids: (list) } (map-get? user-collections { user: tx-sender })))
     (current-total (default-to u0 (get total-amount (map-get? user-total-waste { user: tx-sender })))))
    (map-set waste-collections
      { collection-id: new-collection-id }
      {
        user: tx-sender,
        waste-type: waste-type,
        amount: amount,
        timestamp: block-height,
        verified: false
      }
    )
    (map-set user-collections
      { user: tx-sender }
      { collection-ids: (unwrap! (as-max-len? (append (get collection-ids user-collection-list) new-collection-id) u100) ERR_UNAUTHORIZED) }
    )
    (map-set user-total-waste
      { user: tx-sender }
      { total-amount: (+ current-total amount) }
    )
    (var-set collection-id-nonce new-collection-id)
    (ok new-collection-id)
  )
)

(define-public (verify-waste-collection (collection-id uint))
  (let
    ((collection (unwrap! (map-get? waste-collections { collection-id: collection-id }) ERR_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set waste-collections
      { collection-id: collection-id }
      (merge collection { verified: true })
    ))
  )
)

(define-read-only (get-total-waste-collected (user principal))
  (default-to u0 (get total-amount (map-get? user-total-waste { user: user })))
)

