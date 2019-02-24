(import
  (scheme)
  (chicken base)
  (chicken pretty-print)
  (args)
  (matchable)
  (board)
  (ui))

(define size 4)

(define board-have (make-blank-board size))
(define board-want (make-rand-board size))
(define cursor (make-cursor size 0 0))

(ui-setup)

(win-init size)

(win-redraw board-have board-want cursor)

(let loop ((input (read-input))
           (quit? #f))
  (match input
    ((or 'up 'down 'left 'right)
     (begin
       (set! cursor (move-cursor cursor input))
       (set-cursor cursor)
       (win-refresh)))
    ('quit (set! quit? #t))
    ('flip
     (begin
      (board-bit-flip! board-have (cursor-y cursor) (cursor-x cursor))
      (win-redraw board-have board-want cursor)))
    (_ (void)))
  (unless quit?
    (loop (read-input) #f)))

(ui-shutdown)


