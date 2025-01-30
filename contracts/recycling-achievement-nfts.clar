;; Recycling Achievement NFTs Contract

(define-non-fungible-token recycling-achievement uint)

(define-map achievement-data
  { token-id: uint }
  {
    user: principal,
    achievement-type: (string-ascii 50),
    description: (string-utf8 256),
    timestamp: uint
  }
)

(define-data-var token-id-nonce uint u0)

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u403))

(define-read-only (get-last-token-id)
  (ok (var-get token-id-nonce))
)

(define-read-only (get-token-uri (token-id uint))
  (ok none)
)

(define-read-only (get-owner (token-id uint))
  (ok (nft-get-owner? recycling-achievement token-id))
)

(define-public (transfer (token-id uint) (sender principal) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender sender) ERR_UNAUTHORIZED)
    (nft-transfer? recycling-achievement token-id sender recipient)
  )
)

(define-public (mint-achievement (user principal) (achievement-type (string-ascii 50)) (description (string-utf8 256)))
  (let
    ((new-token-id (+ (var-get token-id-nonce) u1)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (try! (nft-mint? recycling-achievement new-token-id user))
    (map-set achievement-data
      { token-id: new-token-id }
      {
        user: user,
        achievement-type: achievement-type,
        description: description,
        timestamp: block-height
      }
    )
    (var-set token-id-nonce new-token-id)
    (ok new-token-id)
  )
)

(define-read-only (get-achievement-data (token-id uint))
  (map-get? achievement-data { token-id: token-id })
)

