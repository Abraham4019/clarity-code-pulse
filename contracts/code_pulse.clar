;; CodePulse - Educational Platform Smart Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-enrolled (err u103))

;; Data Variables
(define-data-var next-course-id uint u0)
(define-data-var next-certificate-id uint u0)

;; Define token for rewards
(define-fungible-token pulse-token)

;; Data Maps
(define-map courses uint {
    title: (string-ascii 50),
    creator: principal,
    price: uint,
    active: bool
})

(define-map enrollments (tuple (student principal) (course-id uint)) {
    enrolled: bool,
    progress: uint,
    completed: bool
})

(define-map certificates uint {
    student: principal,
    course-id: uint,
    timestamp: uint
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
                active: true
            })
            (var-set next-course-id (+ course-id u1))
            (ok course-id)
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
                completed: false
            })
            (ok true)
        )
    ))
)

;; Progress Tracking
(define-public (update-progress (course-id uint) (progress uint))
    (let (
        (enrollment (unwrap! (map-get? enrollments {student: tx-sender, course-id: course-id}) err-not-enrolled))
    )
    (if (get enrolled enrollment)
        (begin
            (map-set enrollments {student: tx-sender, course-id: course-id} 
                (merge enrollment {progress: progress}))
            (ok true)
        )
        err-not-enrolled
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

(define-read-only (get-student-progress (student principal) (course-id uint))
    (ok (map-get? enrollments {student: student, course-id: course-id}))
)

(define-read-only (verify-certificate (cert-id uint))
    (ok (map-get? certificates cert-id))
)