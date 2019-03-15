(import
  (scheme)
  (chicken base)
  (chicken condition)
  (chicken process-context)
  (args)
  (matchable)
  (board)
  (ui)
  (cursor)
  (utils))

(current-exception-handler
  (lambda (exn)
    (print-error-message exn (current-error-port))
    (exit 1)))

(define (get-size-arg)
  (define (valid-size? size)
    (and (number? size)
         (>= size 4)
         (<= size 16)))
  (args:width 16)
  (args:indent 2)
  (define opts
    (list (args:make-option (s size) (required: "size") "Board size"
            (set! arg (if arg (string->number arg) #f)))
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
      (if (valid-size? size) size #f))))

(define (config-file)
  (let ((home (get-environment-variable "HOME")))
    (if home
        (string-append home "/.config/flip-bits.conf")
        (error "No HOME environment variable"))))

(define (read-config)
  (let ((conf-file (config-file)))
    (call/cc
      (lambda (k)
        (with-exception-handler
          (lambda (exn) (k '()))
          (lambda ()
            (with-input-from-file conf-file read)))))))

(define (write-config conf)
  (let ((conf-file (config-file)))
    (with-output-to-file conf-file (lambda () (write conf)))))

(define size (or (get-size-arg)
                 (cadr (or (assoc 'size (read-config))
                           '(size 4)))))

(write-config `((size ,size)))

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
        (board-want (make-random-board size))
        (cursor (make-cursor size 0 0))
        (win (window-init size)))
    (window-draw win board-have board-want cursor)
    (let input-loop ()
      (if (equal? board-have board-want)
        (begin (sleep 1)
               (round-loop))
        (let ((input (read-input win)))
          (match input
            ((or 'up 'down 'left 'right)
             (begin
               (set! cursor (cursor-move cursor input))
               (set-cursor-position win cursor)
               (input-loop)))
            ((or 'flip-up 'flip-down 'flip-left 'flip-right)
             (begin
               (multi-flip! board-have cursor input)
               (window-draw win board-have board-want cursor)
               (input-loop)))
            ('flip
             (begin
               (board-bit-flip! board-have
                                (cursor-y cursor)
                                (cursor-x cursor))
               (window-draw win board-have board-want cursor))
               (input-loop))
            ('quit (void))
            ('resize
             (begin
               (window-free win)
               (screen-clear)
               (set! win (window-init size))
               (window-draw win board-have board-want cursor)
               (input-loop)))
            (_ (input-loop))))))))

(ui-shutdown)


