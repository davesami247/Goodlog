(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_HOURS (err u103))
(define-constant ERR_INVALID_ORGANIZATION (err u104))
(define-constant ERR_CANNOT_VERIFY_OWN (err u105))

(define-data-var next-log-id uint u1)
(define-data-var total-volunteer-hours uint u0)

(define-map volunteer-logs
  uint
  {
    volunteer: principal,
    organization: principal,
    hours: uint,
    description: (string-ascii 500),
    timestamp: uint,
    block-height: uint,
    verified: bool,
    verifier: (optional principal)
  }
)

(define-map volunteer-stats
  principal
  {
    total-hours: uint,
    total-logs: uint,
    verified-hours: uint,
    verified-logs: uint
  }
)

(define-map organization-stats
  principal
  {
    total-hours-received: uint,
    total-logs-received: uint,
    verified-hours: uint,
    verified-logs: uint
  }
)

(define-map volunteer-organization-logs
  { volunteer: principal, organization: principal }
  (list 100 uint)
)

(define-map organization-verifiers
  principal
  (list 10 principal)
)

(define-public (register-organization (verifiers (list 10 principal)))
  (begin
    (map-set organization-verifiers tx-sender verifiers)
    (ok true)
  )
)

(define-public (add-verifier (organization principal) (verifier principal))
  (let ((current-verifiers (default-to (list) (map-get? organization-verifiers organization))))
    (asserts! (is-eq tx-sender organization) ERR_UNAUTHORIZED)
    (map-set organization-verifiers organization (unwrap-panic (as-max-len? (append current-verifiers verifier) u10)))
    (ok true)
  )
)

(define-public (log-volunteer-work (organization principal) (hours uint) (description (string-ascii 500)))
  (let (
    (log-id (var-get next-log-id))
    (current-height stacks-block-height)
    (current-time (unwrap-panic (get-stacks-block-info? time current-height)))
  )
    (asserts! (> hours u0) ERR_INVALID_HOURS)
    (asserts! (not (is-eq tx-sender organization)) ERR_INVALID_ORGANIZATION)
    
    (map-set volunteer-logs log-id {
      volunteer: tx-sender,
      organization: organization,
      hours: hours,
      description: description,
      timestamp: current-time,
      block-height: current-height,
      verified: false,
      verifier: none
    })
    
    (update-volunteer-stats tx-sender hours false)
    (update-organization-stats organization hours false)
    (update-volunteer-organization-logs tx-sender organization log-id)
    
    (var-set next-log-id (+ log-id u1))
    (ok log-id)
  )
)

(define-public (verify-volunteer-work (log-id uint))
  (let ((log-data (unwrap! (map-get? volunteer-logs log-id) ERR_NOT_FOUND)))
    (asserts! (not (get verified log-data)) ERR_ALREADY_EXISTS)
    (asserts! (not (is-eq tx-sender (get volunteer log-data))) ERR_CANNOT_VERIFY_OWN)
    (asserts! (is-authorized-verifier tx-sender (get organization log-data)) ERR_UNAUTHORIZED)
    
    (map-set volunteer-logs log-id (merge log-data {
      verified: true,
      verifier: (some tx-sender)
    }))
    
    (update-volunteer-stats (get volunteer log-data) (get hours log-data) true)
    (update-organization-stats (get organization log-data) (get hours log-data) true)
    (var-set total-volunteer-hours (+ (var-get total-volunteer-hours) (get hours log-data)))
    
    (ok true)
  )
)

(define-private (is-authorized-verifier (verifier principal) (organization principal))
  (let ((verifiers (default-to (list) (map-get? organization-verifiers organization))))
    (or 
      (is-eq verifier organization)
      (is-some (index-of verifiers verifier))
    )
  )
)

(define-private (update-volunteer-stats (volunteer principal) (hours uint) (verified bool))
  (let ((current-stats (default-to { total-hours: u0, total-logs: u0, verified-hours: u0, verified-logs: u0 } 
                                  (map-get? volunteer-stats volunteer))))
    (map-set volunteer-stats volunteer {
      total-hours: (+ (get total-hours current-stats) hours),
      total-logs: (+ (get total-logs current-stats) u1),
      verified-hours: (if verified 
                       (+ (get verified-hours current-stats) hours) 
                       (get verified-hours current-stats)),
      verified-logs: (if verified 
                      (+ (get verified-logs current-stats) u1) 
                      (get verified-logs current-stats))
    })
  )
)

(define-private (update-organization-stats (organization principal) (hours uint) (verified bool))
  (let ((current-stats (default-to { total-hours-received: u0, total-logs-received: u0, verified-hours: u0, verified-logs: u0 } 
                                  (map-get? organization-stats organization))))
    (map-set organization-stats organization {
      total-hours-received: (+ (get total-hours-received current-stats) hours),
      total-logs-received: (+ (get total-logs-received current-stats) u1),
      verified-hours: (if verified 
                       (+ (get verified-hours current-stats) hours) 
                       (get verified-hours current-stats)),
      verified-logs: (if verified 
                      (+ (get verified-logs current-stats) u1) 
                      (get verified-logs current-stats))
    })
  )
)

(define-private (update-volunteer-organization-logs (volunteer principal) (organization principal) (log-id uint))
  (let ((current-logs (default-to (list) (map-get? volunteer-organization-logs { volunteer: volunteer, organization: organization }))))
    (map-set volunteer-organization-logs 
             { volunteer: volunteer, organization: organization }
             (unwrap-panic (as-max-len? (append current-logs log-id) u100)))
  )
)

(define-read-only (get-volunteer-log (log-id uint))
  (map-get? volunteer-logs log-id)
)

(define-read-only (get-volunteer-stats (volunteer principal))
  (map-get? volunteer-stats volunteer)
)

(define-read-only (get-organization-stats (organization principal))
  (map-get? organization-stats organization)
)

(define-read-only (get-volunteer-organization-logs (volunteer principal) (organization principal))
  (map-get? volunteer-organization-logs { volunteer: volunteer, organization: organization })
)

(define-read-only (get-organization-verifiers (organization principal))
  (map-get? organization-verifiers organization)
)

(define-read-only (get-total-volunteer-hours)
  (var-get total-volunteer-hours)
)

(define-read-only (get-next-log-id)
  (var-get next-log-id)
)

(define-read-only (get-volunteer-impact-score (volunteer principal))
  (let ((stats (default-to { total-hours: u0, total-logs: u0, verified-hours: u0, verified-logs: u0 } 
                          (map-get? volunteer-stats volunteer))))
    (if (> (get total-logs stats) u0)
      (/ (* (get verified-hours stats) u100) (get total-hours stats))
      u0
    )
  )
)

(define-read-only (is-log-verified (log-id uint))
  (match (map-get? volunteer-logs log-id)
    log-data (get verified log-data)
    false
  )
)

(define-read-only (get-volunteer-verification-rate (volunteer principal))
  (let ((stats (default-to { total-hours: u0, total-logs: u0, verified-hours: u0, verified-logs: u0 } 
                          (map-get? volunteer-stats volunteer))))
    (if (> (get total-logs stats) u0)
      (/ (* (get verified-logs stats) u100) (get total-logs stats))
      u0
    )
  )
)