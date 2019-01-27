(import
  (chicken base)
  (chicken random)
  (chicken time)
  (board))


(let loop ((i 0))
  (let ((b (make-rand-board 4)))
    (board-pp b))
  (if (< i 1000)
      (loop (add1 i))))
