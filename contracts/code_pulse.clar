;; CodePulse - Educational Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-enrolled (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-invalid-progress (err u105))
(define-constant err-cooldown-active (err u106))
(define-constant err-invalid-input (err u107))
(define-constant err-contract-paused (err u108))

;; Data Variables
(define-data-var next-course-id uint u0)
(define-data-var next-certificate-id uint u0)
(define-data-var next-lesson-id uint u0)
(define-data-var contract-paused bool false)
(define-data-var lesson-cooldown uint u3600) ;; 1 hour cooldown

;; Define token for rewards
(define-fungible-token pulse-token)

;; Data Maps
(define-map courses uint {
    title: (string-ascii 50),
    creator: principal, 
    price: uint,
    active: bool,
    lesson-count: uint,
    avg-rating: uint,
    rating-count: uint,
    created-at: uint
})

(define-map enrollments (tuple (student principal) (course-id uint)) {
    enrolled: bool,
    progress: uint,
    completed: bool,
    lessons-completed: (list 20 uint),
    last-activity: uint,
    last-lesson-completion: uint
})

;; Administrative Functions
(define-public (set-contract-pause (paused bool))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set contract-paused paused))
    )
)

(define-public (set-lesson-cooldown (new-cooldown uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set lesson-cooldown new-cooldown))
    )
)

;; Progress and Rewards
(define-public (complete-lesson (course-id uint) (lesson-id uint))
    (let (
        (enrollment (unwrap! (map-get? enrollments {student: tx-sender, course-id: course-id}) err-not-enrolled))
        (lesson (unwrap! (map-get? lessons lesson-id) err-not-found))
        (course (unwrap! (map-get? courses course-id) err-not-found))
        (current-time block-height)
        (last-completion (get last-lesson-completion enrollment))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (get enrolled enrollment) err-not-enrolled)
    (asserts! (>= (- current-time last-completion) (var-get lesson-cooldown)) err-cooldown-active)
    
    (if (> (get progress enrollment) (get lesson-count course))
        (err err-invalid-progress)
        (begin
            (try! (ft-mint? pulse-token (get reward-amount lesson) tx-sender))
            (map-set enrollments {student: tx-sender, course-id: course-id}
                (merge enrollment {
                    lessons-completed: (unwrap! (as-max-len? (append (get lessons-completed enrollment) lesson-id) u20) err-not-found),
                    progress: (+ (get progress enrollment) u1),
                    last-activity: current-time,
                    last-lesson-completion: current-time,
                    completed: (>= (+ (get progress enrollment) u1) (get lesson-count course))
                }))
            (ok true)
        ))
    )
)

;; Getter Functions
(define-read-only (get-student-completed-lessons (student principal) (course-id uint))
    (match (map-get? enrollments {student: student, course-id: course-id})
        enrollment (ok (get lessons-completed enrollment))
        (err err-not-found)
    )
)

[... rest of original contract code ...]
