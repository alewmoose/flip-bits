(module ui
  (ui-setup
   ui-shutdown
   window-init
   window-draw
   window-free
   screen-clear
   set-cursor-position
   read-input)

  (import
    (scheme)
    (chicken base)
    (matchable)
    (chicken format)
    (chicken foreign)
    (board)
    (cursor)
    (utils))

  #>
  #include <ncurses.h>

  #define COLOR_NORMAL COLOR_PAIR(1)
  #define COLOR_BIT_ON (COLOR_PAIR(1) | A_BOLD)
  #define COLOR_BIT_OFF (COLOR_PAIR(1))
  #define COLOR_NUM_CORRECT (COLOR_PAIR(2) | A_BOLD)
  #define COLOR_NUM_NORMAL (COLOR_PAIR(1) | A_BOLD)
  <#

  (define-foreign-type Window (c-pointer "WINDOW"))

  (define ui-setup
    (foreign-lambda* void () "
      initscr();
      start_color();
      noecho();
      cbreak();
      set_escdelay(0);
      init_pair(1, COLOR_WHITE, COLOR_BLACK);
      init_pair(2, COLOR_GREEN, COLOR_BLACK);
      "))

  (define ui-shutdown
    (foreign-lambda* void () "
      endwin();
      "))

  (define window-init
    (foreign-lambda* Window ((int board_size)) "
      int scr_height, scr_width;
      getmaxyx(stdscr, scr_height, scr_width);

      int win_width  = board_size * 2 + 4;
      int win_height = board_size * 2 + 4;
      int win_left   = (scr_width  - win_width)  / 2;
      int win_top    = (scr_height - win_height) / 2;

      WINDOW *win = newwin(win_height, win_width, win_top, win_left);
      keypad(win, true);
      C_return(win);
      "))

  (define window-free
    (foreign-lambda* void ((Window win)) "
      delwin(win);
      "))

  (define (window-draw win board-have board-want cursor)
    (draw-border win (board-size board-have))
    (draw-bits win board-have)
    (draw-row-nums win board-have board-want)
    (draw-col-nums win board-have board-want)
    (set-cursor-position win cursor)
    (win-refresh win))

  (define win-refresh
    (foreign-lambda* void ((Window win)) "
      wrefresh(win);
      "))

  (define draw-border
    (foreign-lambda* void ((Window win) (int size)) "
      wattrset(win, COLOR_NORMAL);
      int len = size * 2;
      mvwvline(win, 1, len, ACS_VLINE, len-1);
      mvwhline(win, len, 0, ACS_HLINE, len);
      mvwaddch(win, len, len, ACS_LRCORNER);
      "))

  (define (draw-bits win board)
    (let ((last (sub1 (board-size board))))
      (for y = 0 to last
        (for x = 0 to last
          (draw-bit win y x (board-bit board y x))))))

  (define draw-bit
    (foreign-lambda* void ((Window win) (int y) (int x) (int bit)) "
      wattrset(win, bit ? COLOR_BIT_ON : COLOR_BIT_OFF);
      mvwaddch(win, y*2 + 1, x*2 + 1, bit + '0');
      "))

  (define (draw-row-nums win board-have board-want)
    (define size (board-size board-want))
    (for i = 0 to (sub1 size)
      (let* ((row-num-have (board-row-num board-have i))
             (row-num-want (board-row-num board-want i))
             (correct-row-num? (= row-num-have row-num-want)))
        (draw-row-num win size i row-num-want correct-row-num?))))

  (define draw-row-num
    (foreign-lambda* void ((Window win)
                           (int size)
                           (int i)
                           (int num)
                           (bool correct)) "
      if (correct)
        wattrset(win, COLOR_NUM_CORRECT);
      else
        wattrset(win, COLOR_NUM_NORMAL);
      int y = 2 * i + 1;
      int x = size * 2 + 1;
      mvwprintw(win, y, x, \"%d\", num);
      "))

  (define (draw-col-nums win board-have board-want)
    (define size (board-size board-want))
    (for i = 0 to (sub1 size)
      (let* ((col-num-have (board-col-num board-have i))
             (col-num-want (board-col-num board-want i))
             (correct-col-num? (= col-num-have col-num-want)))
        (draw-col-num win size i col-num-want correct-col-num?))))

  (define draw-col-num
    (foreign-lambda* void ((Window win)
                           (int size)
                           (int i)
                           (int num)
                           (bool correct)) "
      if (correct)
        wattrset(win, COLOR_NUM_CORRECT);
      else
        wattrset(win, COLOR_NUM_NORMAL);
      char buf[32];
      int y = size * 2 + 1;
      int x = 2 * i + 1;
      snprintf(buf, 32, \"%d\", num);
      char *ch = buf;
      while (*ch) {
        mvwaddch(win, y, x, *ch);
        ch++;
        y++;
      }
      "))

  (define (cursor->win-coords cursor)
    (values (+ (* (cursor-y cursor) 2) 1)
            (+ (* (cursor-x cursor) 2) 1)))

  (define (set-cursor-position win cursor)
    (let-values (((y x) (cursor->win-coords cursor)))
      (wmove win y x)))

  (define wmove
    (foreign-lambda* void ((Window win) (int y) (int x)) "
      wmove(win, y, x);
      "))

  (define (match-sequences seqs gen)
    (define (split-seqs seqs)
      (define (iter left empty nonempty)
          (if (null? left)
            (values empty nonempty)
            (if (null? (cadr (car left)))
              (iter (cdr left) (cons (car left) empty) nonempty)
              (iter (cdr left) empty (cons (car left) nonempty)))))
      (iter seqs '() '()))
    (define (iter left passed want)
      (if (null? left)
        (match-sequences passed gen)
        (let* ((left-first (car left))
               (left-rest (cdr left))
               (val (car left-first))
               (items (cadr left-first))
               (item-first (car items))
               (items-rest (cdr items)))
          (if (equal? item-first want)
            (iter left-rest (cons (list val items-rest) passed) want)
            (iter left-rest passed want)))))
    (let-values (((empty nonempty) (split-seqs seqs)))
      (cond
        ((not (null? empty)) (caar empty))
        ((null? nonempty) #f)
        (else (iter nonempty '() (gen))))))

  (define key-up (foreign-value "KEY_UP" int))
  (define key-down (foreign-value "KEY_DOWN" int))
  (define key-left (foreign-value "KEY_LEFT" int))
  (define key-right (foreign-value "KEY_RIGHT" int))
  (define key-resize (foreign-value "KEY_RESIZE" int))

  (define control-prefix '(27 91 49 59 53))

  (define key-seqs
    `((quit   (,(char->integer #\q)))
      (quit   (,(char->integer #\Q)))
      (resize (,key-resize))
      (flip   (,(char->integer #\space)))
      (up     (,key-up))
      (down   (,key-down))
      (left   (,key-left))
      (right  (,key-right))
      (flip-up    (,@control-prefix 65))
      (flip-down  (,@control-prefix 66))
      (flip-right (,@control-prefix 67))
      (flip-left  (,@control-prefix 68))))

  (define getch
    (foreign-lambda* int ((Window win)) "
      C_return(wgetch(win));
      "))

  (define (read-input win)
    (or (match-sequences key-seqs
                         (lambda () (getch win)))
        (read-input win)))

  (define screen-clear
    (foreign-lambda* void () "
      clear();
      refresh();
      ")))
