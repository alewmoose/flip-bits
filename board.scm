(module board (make-blank-board make-rand-board board-pp)
	(import
    (scheme)
    (chicken base)
    (chicken format)
    (chicken time)
    (chicken pretty-print)
    (chicken random))

  (set-pseudo-random-seed!
    (string-append
      (number->string (current-seconds))
      (number->string (current-milliseconds))))

  (define-syntax for
    (syntax-rules (= to)
      ((_ var = start to end . forms)
       (let loop ((var start))
         (if (<= var end)
           (begin
             (begin . forms)
             (loop (add1 var))))))))

  (define-record board size bits row-nums col-nums)

  (define (make-bits size)
    (let ((bits (make-vector size)))
      (for n = 0 to (- size 1)
        (vector-set! bits n (make-vector size 0)))
      bits))

  (define (make-nums size)
    (make-vector size 0))

  (define (board-pp b)
    (let ((size (board-size b)))
      (newline)
      (printf "--------------------~%")
      (printf "Size: ~a~%" size)
      (printf "--------------------~%")
      (for y = 0 to (- size 1)
        (for x = 0 to (- size 2)
          (printf "~a " (board-bit b y x)))
        (printf "~a~%" (board-bit b y (- size 1)))))
      (printf "--------------------~%")
      (let* ((nums->str (lambda (nums)
                          (foldl string-append ""
                                 (map (lambda (n) (sprintf "~a " n))
                                      (vector->list nums)))))
             (pp-nums (lambda (name v)
                        (printf "~a: ~a~%"
                                name
                                (nums->str v)))))
        (pp-nums "rows" (board-row-nums b))
        (pp-nums "cols" (board-col-nums b)))
      (printf "--------------------~%")
      (newline))

  (define (board-bit b row col)
    (vector-ref
      (vector-ref (board-bits b) row)
      col))

  (define (make-blank-board size)
    (make-board
      size
      (make-bits size)
      (make-nums size)
      (make-nums size)))


  (define (make-rand-board size)
    (make-vector size 1)))




