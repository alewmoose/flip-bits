(module utils (
  while
  until
  for)

  (import scheme)

  (define-syntax while
    (syntax-rules ()
      ((_ pred . forms)
       (let loop ()
         (when pred
           (begin . forms)
           (loop))))))

  (define-syntax until
    (syntax-rules ()
      ((_ pred . forms)
       (while (not pred) . forms))))

  (define-syntax for
    (syntax-rules (to upto)
      ((_ n = s to e . forms)
       (let loop ((n s))
         (when (<= n e)
           (begin . forms)
           (loop (add1 n)))))
      ((_ n = e downto s . forms)
       (let loop ((n e))
         (when (>= n s)
           (begin . forms)
           (loop (sub1 n)))))))

)
