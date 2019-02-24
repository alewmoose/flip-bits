(import
  (scheme)
  (chicken base)
  (chicken pretty-print)
  (args)
  (matchable)
  (board)
  (ui))

(define size 4)

(ui-setup)

(let round-loop ()
  (let ((board-have (make-blank-board size))
        (board-want (make-rand-board size))
        (cursor (make-cursor size 0 0)))
    (win-init size)
    (win-redraw board-have board-want cursor)

    (let input-loop ()
      (let ((input (read-input)))
        (match input
          ((or 'up 'down 'left 'right)
           (begin
             (set! cursor (move-cursor cursor input))
             (set-cursor cursor)
             (win-refresh)
             (input-loop)))
        ('flip
         (begin
           (board-bit-flip! board-have (cursor-y cursor) (cursor-x cursor))
           (win-redraw board-have board-want cursor)
           (if (equal? board-have board-want)
               (begin (sleep 1)
                      (round-loop))
               (input-loop))))
        ('quit (void))
        (_ (input-loop)))))))

(ui-shutdown)


