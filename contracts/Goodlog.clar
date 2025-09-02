(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_HOURS (err u103))
(define-constant ERR_INVALID_ORGANIZATION (err u104))
(define-constant ERR_CANNOT_VERIFY_OWN (err u105))
(define-constant ERR_REPUTATION_NOT_FOUND (err u106))
(define-constant ERR_INVALID_REPUTATION_ACTION (err u107))
(define-constant ERR_INSUFFICIENT_REWARD_BALANCE (err u108))
(define-constant ERR_INVALID_REWARD_RATE (err u109))
(define-constant ERR_REWARD_POOL_NOT_FOUND (err u110))
(define-constant ERR_INSUFFICIENT_TOKENS (err u111))
(define-constant ERR_OPPORTUNITY_NOT_FOUND (err u112))
(define-constant ERR_OPPORTUNITY_CLOSED (err u113))
(define-constant ERR_ALREADY_APPLIED (err u114))
(define-constant ERR_APPLICATION_NOT_FOUND (err u115))
(define-constant ERR_INVALID_SKILL_LEVEL (err u116))

(define-data-var next-log-id uint u1)
(define-data-var total-volunteer-hours uint u0)
(define-data-var reputation-decay-blocks uint u144)
(define-data-var base-reputation-score uint u100)
(define-data-var default-reward-rate uint u10)
(define-data-var total-tokens-distributed uint u0)
(define-data-var next-opportunity-id uint u1)
(define-data-var next-application-id uint u1)

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

(define-map reward-pools
  principal
  {
    total-balance: uint,
    available-balance: uint,
    tokens-distributed: uint,
    reward-rate: uint,
    skill-multipliers: (list 5 { skill: (string-ascii 30), multiplier: uint }),
    pool-active: bool,
    last-updated: uint
  }
)

(define-map volunteer-token-balances
  principal
  {
    earned-tokens: uint,
    withdrawn-tokens: uint,
    available-tokens: uint,
    last-reward-block: uint
  }
)

(define-map skill-categories
  uint
  {
    name: (string-ascii 30),
    base-multiplier: uint,
    description: (string-ascii 100)
  }
)

(define-map token-distribution-history
  { volunteer: principal, distribution-id: uint }
  {
    amount: uint,
    organization: principal,
    hours: uint,
    skill-category: (string-ascii 30),
    block-height: uint,
    log-id: uint
  }
)

;; Volunteer Opportunity Matching System
(define-map volunteer-opportunities
  uint
  {
    organization: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    required-skills: (list 5 (string-ascii 30)),
    min-skill-level: uint,
    estimated-hours: uint,
    max-volunteers: uint,
    current-applications: uint,
    deadline: uint,
    is-active: bool,
    created-block: uint,
    location: (optional (string-ascii 100))
  }
)

(define-map volunteer-skills
  principal
  {
    skills: (list 10 { skill: (string-ascii 30), level: uint, verified: bool }),
    experience-years: uint,
    availability-hours: uint,
    preferred-categories: (list 5 (string-ascii 30)),
    last-updated: uint
  }
)

(define-map opportunity-applications
  uint
  {
    opportunity-id: uint,
    volunteer: principal,
    application-message: (string-ascii 300),
    status: (string-ascii 20),
    applied-block: uint,
    reviewed-block: uint,
    reviewer: (optional principal)
  }
)

(define-public (register-organization (verifiers (list 10 principal)))
  (begin
    (map-set organization-verifiers tx-sender verifiers)
    (initialize-reputation-tiers)
    (initialize-skill-categories)
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

(define-private (initialize-skill-categories)
  (begin
    (map-set skill-categories u1 { name: "General", base-multiplier: u100, description: "General volunteer work" })
    (map-set skill-categories u2 { name: "Technical", base-multiplier: u150, description: "Technical and IT support" })
    (map-set skill-categories u3 { name: "Education", base-multiplier: u130, description: "Teaching and training" })
    (map-set skill-categories u4 { name: "Healthcare", base-multiplier: u140, description: "Medical and health services" })
    (map-set skill-categories u5 { name: "Emergency", base-multiplier: u200, description: "Emergency response work" })
  )
)

(define-public (add-verifier (organization principal) (verifier principal))
  (let ((current-verifiers (default-to (list) (map-get? organization-verifiers organization))))
    (asserts! (is-eq tx-sender organization) ERR_UNAUTHORIZED)
    (map-set organization-verifiers organization (unwrap-panic (as-max-len? (append current-verifiers verifier) u10)))
    (ok true)
  )
)

(define-public (create-reward-pool (initial-balance uint) (reward-rate uint))
  (begin
    (asserts! (> initial-balance u0) ERR_INSUFFICIENT_REWARD_BALANCE)
    (asserts! (> reward-rate u0) ERR_INVALID_REWARD_RATE)
    (map-set reward-pools tx-sender {
      total-balance: initial-balance,
      available-balance: initial-balance,
      tokens-distributed: u0,
      reward-rate: reward-rate,
      skill-multipliers: (list),
      pool-active: true,
      last-updated: stacks-block-height
    })
    (ok true)
  )
)

(define-public (fund-reward-pool (additional-amount uint))
  (let ((current-pool (unwrap! (map-get? reward-pools tx-sender) ERR_REWARD_POOL_NOT_FOUND)))
    (asserts! (> additional-amount u0) ERR_INSUFFICIENT_REWARD_BALANCE)
    (map-set reward-pools tx-sender (merge current-pool {
      total-balance: (+ (get total-balance current-pool) additional-amount),
      available-balance: (+ (get available-balance current-pool) additional-amount),
      last-updated: stacks-block-height
    }))
    (ok true)
  )
)

(define-public (set-skill-multiplier (skill-name (string-ascii 30)) (multiplier uint))
  (let ((current-pool (unwrap! (map-get? reward-pools tx-sender) ERR_REWARD_POOL_NOT_FOUND))
        (new-skill-entry { skill: skill-name, multiplier: multiplier })
        (current-multipliers (get skill-multipliers current-pool)))
    (asserts! (> multiplier u0) ERR_INVALID_REWARD_RATE)
    (map-set reward-pools tx-sender (merge current-pool {
      skill-multipliers: (unwrap-panic (as-max-len? (append current-multipliers new-skill-entry) u5)),
      last-updated: stacks-block-height
    }))
    (ok true)
  )
)

(define-public (withdraw-tokens (amount uint))
  (let ((current-balance (default-to { earned-tokens: u0, withdrawn-tokens: u0, available-tokens: u0, last-reward-block: u0 } 
                                    (map-get? volunteer-token-balances tx-sender))))
    (asserts! (<= amount (get available-tokens current-balance)) ERR_INSUFFICIENT_TOKENS)
    (map-set volunteer-token-balances tx-sender (merge current-balance {
      withdrawn-tokens: (+ (get withdrawn-tokens current-balance) amount),
      available-tokens: (- (get available-tokens current-balance) amount)
    }))
    (ok amount)
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
    (distribute-tokens-for-verified-work (get volunteer log-data) (get organization log-data) (get hours log-data) log-id)
    
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

;; Volunteer Opportunity System Functions
(define-public (create-volunteer-opportunity (title (string-ascii 100)) (description (string-ascii 500)) (required-skills (list 5 (string-ascii 30))) (min-skill-level uint) (estimated-hours uint) (max-volunteers uint) (deadline uint) (location (optional (string-ascii 100))))
  (let (
    (opportunity-id (var-get next-opportunity-id))
    (current-block stacks-block-height)
  )
    (asserts! (> estimated-hours u0) ERR_INVALID_HOURS)
    (asserts! (> max-volunteers u0) ERR_INVALID_ORGANIZATION)
    (asserts! (> deadline current-block) ERR_INVALID_ORGANIZATION)
    (asserts! (and (>= min-skill-level u1) (<= min-skill-level u5)) ERR_INVALID_SKILL_LEVEL)
    
    (map-set volunteer-opportunities opportunity-id {
      organization: tx-sender,
      title: title,
      description: description,
      required-skills: required-skills,
      min-skill-level: min-skill-level,
      estimated-hours: estimated-hours,
      max-volunteers: max-volunteers,
      current-applications: u0,
      deadline: deadline,
      is-active: true,
      created-block: current-block,
      location: location
    })
    
    (var-set next-opportunity-id (+ opportunity-id u1))
    (ok opportunity-id)
  )
)

(define-public (update-volunteer-skills (skills (list 10 { skill: (string-ascii 30), level: uint, verified: bool })) (experience-years uint) (availability-hours uint) (preferred-categories (list 5 (string-ascii 30))))
  (begin
    (asserts! (>= experience-years u0) ERR_INVALID_HOURS)
    (asserts! (>= availability-hours u0) ERR_INVALID_HOURS)
    
    (map-set volunteer-skills tx-sender {
      skills: skills,
      experience-years: experience-years,
      availability-hours: availability-hours,
      preferred-categories: preferred-categories,
      last-updated: stacks-block-height
    })
    (ok true)
  )
)

(define-public (apply-for-opportunity (opportunity-id uint) (application-message (string-ascii 300)))
  (let (
    (opportunity (unwrap! (map-get? volunteer-opportunities opportunity-id) ERR_OPPORTUNITY_NOT_FOUND))
    (application-id (var-get next-application-id))
    (current-block stacks-block-height)
  )
    (asserts! (get is-active opportunity) ERR_OPPORTUNITY_CLOSED)
    (asserts! (< current-block (get deadline opportunity)) ERR_OPPORTUNITY_CLOSED)
    (asserts! (< (get current-applications opportunity) (get max-volunteers opportunity)) ERR_OPPORTUNITY_CLOSED)
    (asserts! (not (is-eq tx-sender (get organization opportunity))) ERR_CANNOT_VERIFY_OWN)
    
    ;; Check if already applied
    (asserts! (is-none (get-existing-application tx-sender opportunity-id)) ERR_ALREADY_APPLIED)
    
    (map-set opportunity-applications application-id {
      opportunity-id: opportunity-id,
      volunteer: tx-sender,
      application-message: application-message,
      status: "pending",
      applied-block: current-block,
      reviewed-block: u0,
      reviewer: none
    })
    
    (map-set volunteer-opportunities opportunity-id 
      (merge opportunity { current-applications: (+ (get current-applications opportunity) u1) })
    )
    
    (var-set next-application-id (+ application-id u1))
    (ok application-id)
  )
)

(define-public (review-application (application-id uint) (approve bool))
  (let (
    (application (unwrap! (map-get? opportunity-applications application-id) ERR_APPLICATION_NOT_FOUND))
    (opportunity (unwrap! (map-get? volunteer-opportunities (get opportunity-id application)) ERR_OPPORTUNITY_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get organization opportunity)) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status application) "pending") ERR_ALREADY_EXISTS)
    
    (map-set opportunity-applications application-id (merge application {
      status: (if approve "approved" "rejected"),
      reviewed-block: stacks-block-height,
      reviewer: (some tx-sender)
    }))
    
    (ok approve)
  )
)

(define-public (close-opportunity (opportunity-id uint))
  (let (
    (opportunity (unwrap! (map-get? volunteer-opportunities opportunity-id) ERR_OPPORTUNITY_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get organization opportunity)) ERR_UNAUTHORIZED)
    
    (map-set volunteer-opportunities opportunity-id (merge opportunity { is-active: false }))
    (ok true)
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

(define-private (distribute-tokens-for-verified-work (volunteer principal) (organization principal) (hours uint) (log-id uint))
  (match (map-get? reward-pools organization)
    pool-data 
    (if (get pool-active pool-data)
      (let (
        (base-reward (* hours (get reward-rate pool-data)))
        (skill-multiplier (get-skill-multiplier-for-general))
        (reputation-multiplier (calculate-reputation-multiplier volunteer))
        (final-reward (/ (* (* base-reward skill-multiplier) reputation-multiplier) u10000))
        (current-balance (default-to { earned-tokens: u0, withdrawn-tokens: u0, available-tokens: u0, last-reward-block: u0 }
                                    (map-get? volunteer-token-balances volunteer)))
        (distribution-id (get earned-tokens current-balance))
      )
        (if (>= (get available-balance pool-data) final-reward)
          (begin
            (map-set reward-pools organization (merge pool-data {
              available-balance: (- (get available-balance pool-data) final-reward),
              tokens-distributed: (+ (get tokens-distributed pool-data) final-reward),
              last-updated: stacks-block-height
            }))
            (map-set volunteer-token-balances volunteer {
              earned-tokens: (+ (get earned-tokens current-balance) final-reward),
              withdrawn-tokens: (get withdrawn-tokens current-balance),
              available-tokens: (+ (get available-tokens current-balance) final-reward),
              last-reward-block: stacks-block-height
            })
            (map-set token-distribution-history 
              { volunteer: volunteer, distribution-id: distribution-id }
              {
                amount: final-reward,
                organization: organization,
                hours: hours,
                skill-category: "General",
                block-height: stacks-block-height,
                log-id: log-id
              }
            )
            (var-set total-tokens-distributed (+ (var-get total-tokens-distributed) final-reward))
          )
          false
        )
      )
      false
    )
    false
  )
)

(define-private (get-skill-multiplier-for-general)
  u100
)

(define-public (deactivate-reward-pool)
  (let ((current-pool (unwrap! (map-get? reward-pools tx-sender) ERR_REWARD_POOL_NOT_FOUND)))
    (map-set reward-pools tx-sender (merge current-pool {
      pool-active: false,
      last-updated: stacks-block-height
    }))
    (ok true)
  )
)

(define-public (activate-reward-pool)
  (let ((current-pool (unwrap! (map-get? reward-pools tx-sender) ERR_REWARD_POOL_NOT_FOUND)))
    (map-set reward-pools tx-sender (merge current-pool {
      pool-active: true,
      last-updated: stacks-block-height
    }))
    (ok true)
  )
)

(define-read-only (get-reward-pool-info (organization principal))
  (map-get? reward-pools organization)
)

(define-read-only (get-volunteer-token-balance (volunteer principal))
  (map-get? volunteer-token-balances volunteer)
)

(define-read-only (get-skill-category-info (category-id uint))
  (map-get? skill-categories category-id)
)

(define-read-only (get-token-distribution-history (volunteer principal) (distribution-id uint))
  (map-get? token-distribution-history { volunteer: volunteer, distribution-id: distribution-id })
)

(define-read-only (get-total-tokens-distributed)
  (var-get total-tokens-distributed)
)

;; Opportunity Matching System Read-Only Functions
(define-read-only (get-volunteer-opportunity (opportunity-id uint))
  (map-get? volunteer-opportunities opportunity-id)
)

(define-read-only (get-volunteer-skills (volunteer principal))
  (map-get? volunteer-skills volunteer)
)

(define-read-only (get-opportunity-application (application-id uint))
  (map-get? opportunity-applications application-id)
)

(define-read-only (get-volunteer-applications (volunteer principal) (opportunity-id uint))
  (get-existing-application volunteer opportunity-id)
)

(define-read-only (get-active-opportunities)
  ;; Returns count of active opportunities (simplified implementation)
  (- (var-get next-opportunity-id) u1)
)

(define-read-only (calculate-skill-match-score (volunteer principal) (opportunity-id uint))
  (match (map-get? volunteer-opportunities opportunity-id)
    opportunity
    (match (map-get? volunteer-skills volunteer)
      volunteer-skills-data
      (let (
        (required-skills (get required-skills opportunity))
        (volunteer-skills-list (get skills volunteer-skills-data))
        (min-level (get min-skill-level opportunity))
      )
        ;; Simplified matching: count matching skills
        (calculate-matching-skills volunteer-skills-list required-skills min-level)
      )
      u0
    )
    u0
  )
)

(define-read-only (calculate-potential-reward (organization principal) (hours uint) (volunteer principal))
  (match (map-get? reward-pools organization)
    pool-data
    (if (get pool-active pool-data)
      (let (
        (base-reward (* hours (get reward-rate pool-data)))
        (skill-multiplier (get-skill-multiplier-for-general))
        (reputation-multiplier (calculate-reputation-multiplier volunteer))
        (final-reward (/ (* (* base-reward skill-multiplier) reputation-multiplier) u10000))
      )
        (some final-reward)
      )
      none
    )
    none
  )
)

;; Private Helper Functions for Opportunity System
(define-private (get-existing-application (volunteer principal) (opportunity-id uint))
  ;; Simplified check - in real implementation would iterate through applications
  none
)

(define-private (calculate-matching-skills (volunteer-skills-list (list 10 { skill: (string-ascii 30), level: uint, verified: bool })) (required-skills (list 5 (string-ascii 30))) (min-level uint))
  ;; Simplified matching algorithm - counts number of matching skills
  (if (> (len required-skills) u0)
    u75 ;; Return 75% match as placeholder
    u0
  )
)


