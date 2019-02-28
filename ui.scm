(module ui (
  ui-setup
  ui-shutdown
  win-init
  win-redraw
  make-cursor
  move-cursor
  cursor-y
  cursor-x
  set-cursor
  read-input
  win-refresh
  )

  (import
    (scheme)
    (chicken base)
    (matchable)
    (chicken format)
    (chicken foreign)
    (board)
    (utils))

  #>
  #include <ncurses.h>

  static WINDOW *win;

  #define COLOR_NORMAL COLOR_PAIR(1)
  #define COLOR_BIT_ON (COLOR_PAIR(1) | A_BOLD)
  #define COLOR_BIT_OFF (COLOR_PAIR(1))
  #define COLOR_NUM_CORRECT (COLOR_PAIR(3) | A_BOLD)
  #define COLOR_NUM_NORMAL (COLOR_PAIR(1) | A_BOLD)
  <#

  (define ui-setup
    (foreign-lambda* void () "
      initscr();
      start_color();
      noecho();
      cbreak();
      set_escdelay(0);
      init_pair(1, COLOR_WHITE,   COLOR_BLACK);
      init_pair(2, COLOR_BLACK,  COLOR_BLACK);
      init_pair(3, COLOR_GREEN,   COLOR_BLACK);
      init_pair(4, COLOR_BLUE,    COLOR_BLACK);
      init_pair(5, COLOR_MAGENTA, COLOR_BLACK);
      init_pair(6, COLOR_CYAN,    COLOR_BLACK);
      init_pair(7, COLOR_RED,     COLOR_BLACK);
      "))

  (define ui-shutdown
    (foreign-lambda* void () "
      endwin();
      "))

  (define win-init
    (foreign-lambda* void ((int board_size)) "
      int scr_height, scr_width;
      getmaxyx(stdscr, scr_height, scr_width);

      int win_width  = board_size * 2 + 4;
      int win_height = board_size * 2 + 4;
      int win_left   = (scr_width  - win_width)  / 2;
      int win_top    = (scr_height - win_height) / 2;

      win = newwin(win_height, win_width, win_top, win_left);
      keypad(win, true);
      "))

  (define (win-redraw board-have board-want cursor)
    (draw-border (board-size board-have))
    (draw-bits board-have)
    (draw-row-nums board-have board-want)
    (draw-col-nums board-have board-want)
    (set-cursor cursor)
    (win-refresh))

  (define win-refresh
    (foreign-lambda* void () "
      wrefresh(win);
      "))

  (define draw-border
    (foreign-lambda* void ((int size)) "
      wattrset(win, COLOR_NORMAL);
      int len = size * 2;
      mvwvline(win, 1, len, ACS_VLINE, len-1);
      mvwhline(win, len, 0, ACS_HLINE, len);
      mvwaddch(win, len, len, ACS_LRCORNER);
      "))

  (define (draw-bits board)
    (let ((last (sub1 (board-size board))))
      (for y = 0 to last
        (for x = 0 to last
          (draw-bit y x (board-bit board y x))))))

  (define draw-bit
    (foreign-lambda* void ((int y) (int x) (int bit)) "
      wattrset(win, bit ? COLOR_BIT_ON : COLOR_BIT_OFF);
      mvwaddch(win, y*2 + 1, x*2 + 1, bit + '0');
      "))

  (define (draw-row-nums board-have board-want)
    (define size (board-size board-want))
    (for i = 0 to (sub1 size)
      (let* ((row-num-have (board-row-num board-have i))
             (row-num-want (board-row-num board-want i))
             (correct-row-num? (= row-num-have row-num-want)))
        (draw-row-num size i row-num-want correct-row-num?))))

  (define draw-row-num
    (foreign-lambda* void ((int size)
                           (int i)
                           (int num)
                           (bool correct)) "
      if (correct)
        wattron(win, COLOR_NUM_CORRECT);
      else
        wattron(win, COLOR_NUM_NORMAL);
      int y = 2 * i + 1;
      int x = size * 2 + 1;
      mvwprintw(win, y, x, \"%d\", num);
      "))

  (define (draw-col-nums board-have board-want)
    (define size (board-size board-want))
    (for i = 0 to (sub1 size)
      (let* ((col-num-have (board-col-num board-have i))
             (col-num-want (board-col-num board-want i))
             (correct-col-num? (= col-num-have col-num-want)))
        (draw-col-num size i col-num-want correct-col-num?))))

  (define draw-col-num
    (foreign-lambda* void ((int size)
                           (int i)
                           (int num)
                           (bool correct)) "
      if (correct)
        wattron(win, COLOR_NUM_CORRECT);
      else
        wattron(win, COLOR_NUM_NORMAL);
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
      wattron(win, COLOR_NORMAL);
      "))

  (define-record cursor size y x)

  (define (move-cursor cursor dir)
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
                       (modulo nx size))))

  (define (cursor->win-coords cursor)
    (values (+ (* (cursor-y cursor) 2) 1)
            (+ (* (cursor-x cursor) 2) 1)))

  (define (set-cursor cursor)
    (let-values (((y x) (cursor->win-coords cursor)))
      (wmove y x)))

  (define wmove
    (foreign-lambda* void ((int y) (int x)) "
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

  (define key-seqs
    `((quit (,(char->integer #\q)))
      (quit (,(char->integer #\Q)))
      (flip (,(char->integer #\space)))
      (up    (,key-up))
      (down  (,key-down))
      (left  (,key-left))
      (right (,key-right))
      (flip-up    (27 91 49 59 53 65))
      (flip-down  (27 91 49 59 53 66))
      (flip-right (27 91 49 59 53 67))
      (flip-left  (27 91 49 59 53 68))))

  (define getch
    (foreign-lambda* int () "
      C_return(wgetch(win));
      "))

  (define (read-input)
    (let ((input (match-sequences key-seqs getch)))
      (or input (read-input))))

)
