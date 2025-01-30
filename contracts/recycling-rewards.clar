;; Recycling Rewards Contract

(define-fungible-token recycling-token)

(define-map user-rewards
  { user: principal }
  { balance: uint }
)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))
(define-constant ERR_INSUFFICIENT_BALANCE (err u401))

(define-read-only (get-balance (user principal))
  (default-to u0 (get balance (map-get? user-rewards { user: user })))
)

(define-public (mint-rewards (recipient principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ft-mint? recycling-token amount recipient)
  )
)

(define-public (transfer (recipient principal) (amount uint))
  (let
    ((sender-balance (get-balance tx-sender)))
    (asserts! (>= sender-balance amount) ERR_INSUFFICIENT_BALANCE)
    (try! (ft-transfer? recycling-token amount tx-sender recipient))
    (map-set user-rewards
      { user: tx-sender }
      { balance: (- sender-balance amount) }
    )
    (map-set user-rewards
      { user: recipient }
      { balance: (+ (get-balance recipient) amount) }
    )
    (ok true)
  )
)

(define-public (reward-user (user principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (try! (ft-mint? recycling-token amount user))
    (map-set user-rewards
      { user: user }
      { balance: (+ (get-balance user) amount) }
    )
    (ok true)
  )
)

