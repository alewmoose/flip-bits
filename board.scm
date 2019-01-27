(module board (make-blank-board make-rand-board board-pp)

	(import
    (scheme)
    (chicken base)
    (chicken format)
    (chicken time)
    (chicken pretty-print)
    (chicken random))

  (define-record board size bits row-nums col-nums)

  (define-syntax for
    (syntax-rules (= to)
      ((_ var = start to end . forms)
       (let loop ((var start))
         (if (<= var end)
           (begin
             (begin . forms)
             (loop (add1 var))))))))

  (define (make-bits size)
    (let ((bits (make-vector size)))
      (for n = 0 to (- size 1)
        (vector-set! bits n (make-vector size 0)))
      bits))

  (define (make-nums size)
    (make-vector size 0))

  (define (board-pp b)
    (define (nums->str nums)
      (foldl string-append ""
             (map (lambda (n) (sprintf "~a " n))
                  (vector->list nums))))
    (define (pp-nums name v) (printf "~a: ~a~%" name (nums->str v)))
    (define (p-header b) (printf "Size: ~a~%" (board-size b)))
    (define (p-bits b)
      (let ((size (board-size b)))
        (for y = 0 to (- size 1)
          (for x = 0 to (- size 2)
            (printf "~a " (board-bit b y x)))
          (printf "~a~%" (board-bit b y (- size 1))))))
    (define (p-footer b)
      (pp-nums "rows" (board-row-nums b))
      (pp-nums "cols" (board-col-nums b)))
    (define (p-vline) (printf "----~%"))
    (newline)
    (p-vline)
    (p-header b)
    (p-vline)
    (p-bits b)
    (p-vline)
    (p-footer b)
    (p-vline)
    (newline))

  (define (board-bit b row col)
    (vector-ref
      (vector-ref (board-bits b) row)
      col))

  (define (board-bit-set! b row col val)
    (vector-set! (vector-ref (board-bits b) row) col val))


  (define (make-blank-board size)
    (make-board
      size
      (make-bits size)
      (make-nums size)
      (make-nums size)))

  (define (make-rand-board size)
    (define nr-cells (* size size))
    (define (set-rand-bit! b)
      (let ((y (pseudo-random-integer size))
            (x (pseudo-random-integer size)))
        (if (= (board-bit b y x) 1)
            (set-rand-bit! b)
            (board-bit-set! b y x 1))))
    (define (board-rand-fill! b size)
      (let* ((min-nr (floor (* nr-cells 1/4)))
            (max-nr (floor (* nr-cells 3/4)))
            (to-set (+ min-nr
                       (pseudo-random-integer (- max-nr min-nr)))))
        (let loop ((i to-set))
          (if (> i 0)
              (begin
                (set-rand-bit! b)
                (loop (sub1 i)))))))
    (let ((b (make-blank-board size)))
      (board-rand-fill! b size)
      b))
)


