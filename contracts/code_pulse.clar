;; CodePulse - Educational Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-enrolled (err u103))
(define-constant err-invalid-rating (err u104))

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
    lessons-completed: (list 20 uint)
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
(define-public (create-course (title (string-ascii 50)) (price uint))
    (let (
        (course-id (var-get next-course-id))
    )
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set courses course-id {
                title: title,
                creator: tx-sender,
                price: price,
                active: true,
                lesson-count: u0,
                avg-rating: u0,
                rating-count: u0
            })
            (var-set next-course-id (+ course-id u1))
            (ok course-id)
        )
        err-owner-only
    ))
)

;; Lesson Management
(define-public (add-lesson (course-id uint) (title (string-ascii 50)) (reward uint))
    (let (
        (lesson-id (var-get next-lesson-id))
        (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set lessons lesson-id {
                course-id: course-id,
                title: title,
                reward-amount: reward
            })
            (map-set courses course-id 
                (merge course {lesson-count: (+ (get lesson-count course) u1)}))
            (var-set next-lesson-id (+ lesson-id u1))
            (ok lesson-id)
        )
        err-owner-only
    ))
)

;; Enrollment Functions
(define-public (enroll-in-course (course-id uint))
    (let (
        (course (unwrap! (map-get? courses course-id) err-not-found))
    )
    (if (default-to false (get enrolled (map-get? enrollments {student: tx-sender, course-id: course-id})))
        err-already-exists
        (begin
            (try! (ft-transfer? pulse-token (get price course) tx-sender (get creator course)))
            (map-set enrollments {student: tx-sender, course-id: course-id} {
                enrolled: true,
                progress: u0,
                completed: false,
                lessons-completed: (list)
            })
            (ok true)
        )
    ))
)

;; Progress and Rewards
(define-public (complete-lesson (course-id uint) (lesson-id uint))
    (let (
        (enrollment (unwrap! (map-get? enrollments {student: tx-sender, course-id: course-id}) err-not-enrolled))
        (lesson (unwrap! (map-get? lessons lesson-id) err-not-found))
    )
    (if (get enrolled enrollment)
        (begin
            (try! (ft-mint? pulse-token (get reward-amount lesson) tx-sender))
            (map-set enrollments {student: tx-sender, course-id: course-id}
                (merge enrollment {
                    lessons-completed: (unwrap! (as-max-len? (append (get lessons-completed enrollment) lesson-id) u20) err-not-found),
                    progress: (+ (get progress enrollment) u1)
                }))
            (ok true)
        )
        err-not-enrolled
    ))
)

;; Rating System
(define-public (rate-lesson (lesson-id uint) (rating uint) (comment (string-ascii 140)))
    (let (
        (lesson (unwrap! (map-get? lessons lesson-id) err-not-found))
        (course (unwrap! (map-get? courses (get course-id lesson)) err-not-found))
    )
    (if (and (>= rating u1) (<= rating u5))
        (begin
            (map-set lesson-ratings {student: tx-sender, lesson-id: lesson-id} {
                rating: rating,
                comment: comment
            })
            (map-set courses (get course-id lesson)
                (merge course {
                    avg-rating: (/ (+ (* (get avg-rating course) (get rating-count course)) rating)
                                 (+ (get rating-count course) u1)),
                    rating-count: (+ (get rating-count course) u1)
                }))
            (ok true)
        )
        err-invalid-rating
    ))
)

;; Certificate Issuance
(define-public (issue-certificate (course-id uint) (student principal))
    (let (
        (cert-id (var-get next-certificate-id))
        (enrollment (unwrap! (map-get? enrollments {student: student, course-id: course-id}) err-not-enrolled))
    )
    (if (and (is-eq tx-sender contract-owner) (get completed enrollment))
        (begin
            (map-set certificates cert-id {
                student: student,
                course-id: course-id,
                timestamp: block-height
            })
            (var-set next-certificate-id (+ cert-id u1))
            (try! (ft-mint? pulse-token u100 student))
            (ok cert-id)
        )
        err-owner-only
    ))
)

;; Getter Functions
(define-read-only (get-course (course-id uint))
    (ok (map-get? courses course-id))
)

(define-read-only (get-lesson (lesson-id uint))
    (ok (map-get? lessons lesson-id))
)

(define-read-only (get-student-progress (student principal) (course-id uint))
    (ok (map-get? enrollments {student: student, course-id: course-id}))
)

(define-read-only (get-lesson-rating (student principal) (lesson-id uint))
    (ok (map-get? lesson-ratings {student: student, lesson-id: lesson-id}))
)

(define-read-only (verify-certificate (cert-id uint))
    (ok (map-get? certificates cert-id))
)
