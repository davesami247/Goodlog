(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_HOURS (err u103))
(define-constant ERR_INVALID_ORGANIZATION (err u104))
(define-constant ERR_CANNOT_VERIFY_OWN (err u105))
(define-constant ERR_REPUTATION_NOT_FOUND (err u106))
(define-constant ERR_INVALID_REPUTATION_ACTION (err u107))

(define-data-var next-log-id uint u1)
(define-data-var total-volunteer-hours uint u0)
(define-data-var reputation-decay-blocks uint u144)
(define-data-var base-reputation-score uint u100)

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

(define-map volunteer-reputation
  principal
  {
    base-score: uint,
    consistency-score: uint,
    quality-score: uint,
    engagement-score: uint,
    total-score: uint,
    tier: uint,
    last-activity-block: uint,
    consecutive-days: uint,
    total-organizations: uint,
    reputation-events: uint
  }
)

(define-map reputation-tiers
  uint
  {
    name: (string-ascii 20),
    min-score: uint,
    max-score: uint,
    benefits-multiplier: uint
  }
)

(define-map daily-activity-streaks
  { volunteer: principal, day: uint }
  { active: bool, hours: uint }
)

(define-map reputation-history
  { volunteer: principal, event-id: uint }
  {
    event-type: (string-ascii 50),
    score-change: int,
    block-height: uint,
    details: (string-ascii 200)
  }
)

(define-public (register-organization (verifiers (list 10 principal)))
  (begin
    (map-set organization-verifiers tx-sender verifiers)
    (initialize-reputation-tiers)
    (ok true)
  )
)

(define-private (initialize-reputation-tiers)
  (begin
    (map-set reputation-tiers u1 { name: "Newcomer", min-score: u0, max-score: u299, benefits-multiplier: u100 })
    (map-set reputation-tiers u2 { name: "Regular", min-score: u300, max-score: u599, benefits-multiplier: u110 })
    (map-set reputation-tiers u3 { name: "Dedicated", min-score: u600, max-score: u899, benefits-multiplier: u125 })
    (map-set reputation-tiers u4 { name: "Champion", min-score: u900, max-score: u1199, benefits-multiplier: u150 })
    (map-set reputation-tiers u5 { name: "Legend", min-score: u1200, max-score: u9999, benefits-multiplier: u200 })
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
    (update-volunteer-reputation-on-log tx-sender organization hours current-height)
    
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
    (update-volunteer-reputation-on-verification (get volunteer log-data) (get hours log-data))
    
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

(define-private (update-volunteer-reputation-on-log (volunteer principal) (organization principal) (hours uint) (current-block-height uint))
  (let (
    (current-rep (default-to { 
      base-score: (var-get base-reputation-score), 
      consistency-score: u0, 
      quality-score: u0, 
      engagement-score: u0, 
      total-score: (var-get base-reputation-score), 
      tier: u1, 
      last-activity-block: current-block-height, 
      consecutive-days: u1, 
      total-organizations: u1, 
      reputation-events: u0 
    } (map-get? volunteer-reputation volunteer)))
    (day-key (/ current-block-height u144))
    (days-since-last (if (> current-block-height (get last-activity-block current-rep))
                       (/ (- current-block-height (get last-activity-block current-rep)) u144)
                       u0))
    (is-consecutive (< days-since-last u2))
    (new-consecutive-days (if is-consecutive 
                           (+ (get consecutive-days current-rep) u1) 
                           u1))
    (consistency-bonus (if (> new-consecutive-days u7) u20 u0))
    (engagement-bonus (if (< (* hours u2) u50) (* hours u2) u50))
    (new-engagement-score (+ (get engagement-score current-rep) engagement-bonus))
    (new-consistency-score (+ (get consistency-score current-rep) consistency-bonus))
    (updated-orgs (calculate-unique-organizations volunteer organization))
    (diversity-bonus (if (> updated-orgs (get total-organizations current-rep)) u15 u0))
    (new-base-score (+ (get base-score current-rep) u5 diversity-bonus))
    (new-total-score (+ new-base-score new-consistency-score (get quality-score current-rep) new-engagement-score))
    (new-tier (calculate-reputation-tier new-total-score))
  )
    (map-set daily-activity-streaks { volunteer: volunteer, day: day-key } { active: true, hours: hours })
    (map-set volunteer-reputation volunteer {
      base-score: new-base-score,
      consistency-score: new-consistency-score,
      quality-score: (get quality-score current-rep),
      engagement-score: new-engagement-score,
      total-score: new-total-score,
      tier: new-tier,
      last-activity-block: current-block-height,
      consecutive-days: new-consecutive-days,
      total-organizations: (if (> updated-orgs (get total-organizations current-rep)) updated-orgs (get total-organizations current-rep)),
      reputation-events: (+ (get reputation-events current-rep) u1)
    })
    (add-reputation-history volunteer "volunteer_activity" (+ u5 consistency-bonus diversity-bonus) current-block-height "Logged volunteer hours")
  )
)

(define-private (update-volunteer-reputation-on-verification (volunteer principal) (hours uint))
  (let (
    (current-rep (unwrap! (map-get? volunteer-reputation volunteer) false))
    (quality-bonus (if (< (* hours u3) u30) (* hours u3) u30))
    (verification-bonus u25)
    (new-quality-score (+ (get quality-score current-rep) quality-bonus verification-bonus))
    (new-total-score (+ (get base-score current-rep) (get consistency-score current-rep) new-quality-score (get engagement-score current-rep)))
    (new-tier (calculate-reputation-tier new-total-score))
  )
    (map-set volunteer-reputation volunteer (merge current-rep {
      quality-score: new-quality-score,
      total-score: new-total-score,
      tier: new-tier,
      reputation-events: (+ (get reputation-events current-rep) u1)
    }))
    (add-reputation-history volunteer "work_verified" (+ quality-bonus verification-bonus) stacks-block-height "Volunteer work verified")
  )
)

(define-private (calculate-unique-organizations (volunteer principal) (new-org principal))
  (let ((current-count u1))
    (+ current-count u1)
  )
)

(define-private (calculate-reputation-tier (score uint))
  (if (<= score u299) u1
    (if (<= score u599) u2
      (if (<= score u899) u3
        (if (<= score u1199) u4 u5))))
)

(define-private (add-reputation-history (volunteer principal) (event-type (string-ascii 50)) (score-change uint) (event-block-height uint) (details (string-ascii 200)))
  (let (
    (current-rep (unwrap-panic (map-get? volunteer-reputation volunteer)))
    (event-id (get reputation-events current-rep))
  )
    (map-set reputation-history 
      { volunteer: volunteer, event-id: event-id }
      {
        event-type: event-type,
        score-change: (to-int score-change),
        block-height: event-block-height,
        details: details
      }
    )
  )
)

(define-public (apply-reputation-decay (volunteer principal))
  (let (
    (current-rep (unwrap! (map-get? volunteer-reputation volunteer) ERR_REPUTATION_NOT_FOUND))
    (blocks-inactive (- stacks-block-height (get last-activity-block current-rep)))
    (decay-threshold (var-get reputation-decay-blocks))
  )
    (asserts! (> blocks-inactive decay-threshold) ERR_INVALID_REPUTATION_ACTION)
    (let (
      (decay-rate (/ blocks-inactive decay-threshold))
      (consistency-decay (if (< (get consistency-score current-rep) (* decay-rate u10)) (get consistency-score current-rep) (* decay-rate u10)))
      (engagement-decay (if (< (get engagement-score current-rep) (* decay-rate u5)) (get engagement-score current-rep) (* decay-rate u5)))
      (new-consistency-score (- (get consistency-score current-rep) consistency-decay))
      (new-engagement-score (- (get engagement-score current-rep) engagement-decay))
      (new-total-score (+ (get base-score current-rep) new-consistency-score (get quality-score current-rep) new-engagement-score))
      (new-tier (calculate-reputation-tier new-total-score))
    )
      (map-set volunteer-reputation volunteer (merge current-rep {
        consistency-score: new-consistency-score,
        engagement-score: new-engagement-score,
        total-score: new-total-score,
        tier: new-tier,
        consecutive-days: u0,
        reputation-events: (+ (get reputation-events current-rep) u1)
      }))
      (add-reputation-history volunteer "reputation_decay" (+ consistency-decay engagement-decay) stacks-block-height "Reputation decay due to inactivity")
      (ok true)
    )
  )
)

(define-read-only (get-volunteer-reputation (volunteer principal))
  (map-get? volunteer-reputation volunteer)
)

(define-read-only (get-reputation-tier-info (tier uint))
  (map-get? reputation-tiers tier)
)

(define-read-only (get-volunteer-reputation-history (volunteer principal) (event-id uint))
  (map-get? reputation-history { volunteer: volunteer, event-id: event-id })
)

(define-read-only (get-daily-activity-streak (volunteer principal) (day uint))
  (map-get? daily-activity-streaks { volunteer: volunteer, day: day })
)

(define-read-only (calculate-reputation-multiplier (volunteer principal))
  (match (map-get? volunteer-reputation volunteer)
    rep-data (match (map-get? reputation-tiers (get tier rep-data))
                tier-data (get benefits-multiplier tier-data)
                u100)
    u100
  )
)