(import (chicken format)
        (chicken pretty-print)
        (chicken bitwise)
        (chicken random))

(import (srfi-9))

;; TODO: write a macro for N-dimensional loops?
(define (range-iter from to fun)
  (let loop ((i from))
    (if (> i to) #f
      (begin
        (fun i)
        (loop (add1 i))))))


(define (coord-iter size fun)
  (range-iter
    0
    (sub1 size)
    (lambda (y)
      (range-iter
        0
        (sub1 size)
        (lambda (x) (fun y x))))))

(define (board-set board y x val)
  (vector-set! (vector-ref board y) x val))

(define (board-get board y x)
  (vector-ref (vector-ref board y) x))

(define (make-board n)
  (define (empty-board)
    (let ((board (make-vector n)))
      (let loop ((i 0))
        (if (>= i n)
          board
          (begin
            (vector-set! board i (make-vector n 0))
            (loop (add1 i)))))))
  (let ((board (empty-board)))
    (coord-iter
      n
      (lambda (y x)
        (board-set board y x (pseudo-random-integer 2))))
    board))

(define (board-pp board)
  (coord-iter
    (vector-length board)
    (lambda (row col)
      (printf "~a~a"
              (board-get board row col)
              (if (= (add1 col) (vector-length board)) "\n" " ")))))

(define (set-num-bit nums i bit)
  (vector-set! nums i
               (bitwise-ior (vector-ref nums i) bit)))

(define (make-nums board)
  (let* ((size (vector-length board))
         (row-nums (make-vector size 0))
         (col-nums (make-vector size 0)))
    (coord-iter
      size
      (lambda (row col)
        (let ((val (board-get board row col)))
          (set-num-bit
            col-nums
            col
            (arithmetic-shift val (- size row 1)))
          (set-num-bit
            row-nums
            row
            (arithmetic-shift val ( - size col 1))))))
    (cons row-nums col-nums)))

(let* ((board (make-board 4))
       (nums (make-nums board)))
  (board-pp board)
  (pp nums))



