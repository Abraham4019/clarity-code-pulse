;; CodePulse - Educational Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-enrolled (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-invalid-progress (err u105))

;; Data Variables
(define-data-var next-course-id uint u0)
(define-data-var next-certificate-id uint u0)
(define-data-var next-lesson-id uint u0)

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
    rating-count: uint
})

(define-map enrollments (tuple (student principal) (course-id uint)) {
    enrolled: bool,
    progress: uint,
    completed: bool,
    lessons-completed: (list 20 uint),
    last-activity: uint
})

(define-map certificates uint {
    student: principal,
    course-id: uint,
    timestamp: uint
})

(define-map lessons uint {
    course-id: uint,
    title: (string-ascii 50),
    reward-amount: uint
})

(define-map lesson-ratings (tuple (student principal) (lesson-id uint)) {
    rating: uint,
    comment: (string-ascii 140)
})

;; Course Management Functions  
[... rest of original contract code ...]

;; Progress and Rewards
(define-public (complete-lesson (course-id uint) (lesson-id uint))
    (let (
        (enrollment (unwrap! (map-get? enrollments {student: tx-sender, course-id: course-id}) err-not-enrolled))
        (lesson (unwrap! (map-get? lessons lesson-id) err-not-found))
        (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (if (get enrolled enrollment)
        (begin
            (if (> (get progress enrollment) (get lesson-count course))
                (err err-invalid-progress)
                (begin
                    (try! (ft-mint? pulse-token (get reward-amount lesson) tx-sender))
                    (map-set enrollments {student: tx-sender, course-id: course-id}
                        (merge enrollment {
                            lessons-completed: (unwrap! (as-max-len? (append (get lessons-completed enrollment) lesson-id) u20) err-not-found),
                            progress: (+ (get progress enrollment) u1),
                            last-activity: block-height,
                            completed: (>= (+ (get progress enrollment) u1) (get lesson-count course))
                        }))
                    (ok true)
                ))
        )
        err-not-enrolled
    ))
)

[... rest of original contract code ...]
