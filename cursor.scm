(module cursor
  (make-cursor
   cursor-move
   cursor-y
   cursor-x)

  (import
    (scheme)
    (chicken base)
    (matchable))

  (define-record cursor size y x)

  (define (cursor-move cursor dir)
    (let* ((size (cursor-size cursor))
           (y (cursor-y cursor))
           (x (cursor-x cursor))
           (ny (match dir ('up (sub1 y))
                          ('down (add1 y))
                          (_ y)))
           (nx (match dir ('left (sub1 x))
                          ('right (add1 x))
                          (_ x))))
          (make-cursor size
                       (modulo ny size)
                       (modulo nx size)))))
