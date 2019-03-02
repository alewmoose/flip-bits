(import
  (scheme)
  (chicken base)
  (chicken pretty-print)
  (chicken process-context)
  (args)
  (matchable)
  (board)
  (ui)
  (utils))

(define (get-size-arg)
  (define default-size 4)
  (define (valid-size? size)
    (and (number? size)
         (>= size 4)
         (<= size 16)))
  (args:width 16)
  (args:indent 2)
  (define opts
    (list (args:make-option (s size) (required: "size") "Board size"
            (set! arg (if arg (string->number arg) default-size)))
          (args:make-option (h help) #:none "Display this text"
            (usage))))
  (define (usage)
    (newline)
    (print "Usage: flip-bits [options...]")
    (newline)
    (print "Options:")
    (print (args:usage opts))
    (exit))
  (receive (options operands)
    (args:parse (command-line-arguments) opts)
    (let* ((size-param (assoc 'size options))
           (size (and size-param (cdr size-param))))
      (if (valid-size? size) size default-size))))

(define size (get-size-arg))

(define (multi-flip! board cursor input)
  (let ((last (sub1 (board-size board)))
        (y (cursor-y cursor))
        (x (cursor-x cursor)))
    (match input
      ('flip-up (for y = y downto 0
                     (board-bit-flip! board y x)))
      ('flip-down (for y = y to last
                       (board-bit-flip! board y x)))
      ('flip-left (for x = x downto 0
                       (board-bit-flip! board y x)))
      ('flip-right (for x = x to last
                        (board-bit-flip! board y x))))))
(ui-setup)

(let round-loop ()
  (let ((board-have (make-blank-board size))
        (board-want (make-rand-board size))
        (cursor (make-cursor size 0 0))
        (win (win-init size)))
    (win-draw win board-have board-want cursor)
    (let input-loop ()
      (if (equal? board-have board-want)
        (begin (sleep 1)
               (round-loop))
        (let ((input (read-input win)))
          (match input
            ((or 'up 'down 'left 'right)
             (begin
               (set! cursor (move-cursor cursor input))
               (set-cursor win cursor)
               (input-loop)))
            ((or 'flip-up 'flip-down 'flip-left 'flip-right)
             (begin
               (multi-flip! board-have cursor input)
               (win-draw win board-have board-want cursor)
               (input-loop)))
            ('flip
             (begin
               (board-bit-flip! board-have
                                (cursor-y cursor)
                                (cursor-x cursor))
               (win-draw win board-have board-want cursor))
               (input-loop))
            ('quit (void))
            ('resize
             (begin
               (win-free win)
               (screen-clear)
               (set! win (win-init size))
               (win-draw win board-have board-want cursor)
               (input-loop)))
            (_ (input-loop))))))))

(ui-shutdown)


