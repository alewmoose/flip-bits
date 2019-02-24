(module board (
  make-blank-board
  make-rand-board
  board-bit
  board-bit-flip!
  board-col-num
  board-row-num
  board-size
  )

	(import
    (scheme)
    (chicken base)
    (chicken bitwise)
    (chicken random))

  (define-record board size bits row-nums col-nums)

  (define (make-bits size)
    (let ((bits (make-vector size)))
      (let loop ((n 0))
        (when (< n size)
          (vector-set! bits n (make-vector size 0))
          (loop (add1 n))))
      bits))

  (define (make-nums size)
    (make-vector size 0))

  (define (board-bit b row col)
    (vector-ref (vector-ref (board-bits b)
                            row)
                col))

  (define (board-bit-set! b row col val)
    (define (nums-set! nums numi i val)
      (let ((num (vector-ref nums numi))
            (biti (- (board-size b) i 1)))
        (vector-set!
          nums
          numi
          (if (zero? val)
            (bitwise-and num
                         (bitwise-not (arithmetic-shift 1 biti)))
            (bitwise-ior num
                        (arithmetic-shift 1 biti))))))
    (vector-set! (vector-ref (board-bits b) row) col val)
    (nums-set! (board-row-nums b) row col val)
    (nums-set! (board-col-nums b) col row val))

  (define (board-bit-flip! b row col)
    (board-bit-set!
      b row col
      (modulo (add1 (board-bit b row col)) 2)))

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

  (define (board-col-num b n)
    (vector-ref (board-col-nums b) n))

  (define (board-row-num b n)
    (vector-ref (board-row-nums b) n))

)


