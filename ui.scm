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
    (chicken foreign)
    (board))

  #>
  #include <ncurses.h>

  static WINDOW *win;
  <#

  (define ui-setup
    (foreign-lambda* void () "
      initscr();
      start_color();
      noecho();
      cbreak();
      set_escdelay(0);
      // keypad(stdscr, true);
      /*
      init_pair(1, COLOR_WHITE,   COLOR_BLACK);
      init_pair(2, COLOR_YELLOW,  COLOR_BLACK);
      init_pair(3, COLOR_GREEN,   COLOR_BLACK);
      init_pair(4, COLOR_BLUE,    COLOR_BLACK);
      init_pair(5, COLOR_MAGENTA, COLOR_BLACK);
      init_pair(6, COLOR_CYAN,    COLOR_BLACK);
      init_pair(7, COLOR_RED,     COLOR_BLACK);
      */
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
      // wattrset(win, COLOR_PAIR(1));
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
      int len = size * 2;
      mvwvline(win, 1, len, ACS_VLINE, len-1);
      mvwhline(win, len, 0, ACS_HLINE, len);
      mvwaddch(win, len, len, ACS_LRCORNER);
      "))

  (define (coord-iter size cb)
    (let loop-y ((y 0))
      (let loop-x ((x 0))
        (cb y x)
        (if (< x (sub1 size))
            (loop-x (add1 x))))
      (if (< y (sub1 size))
          (loop-y (add1 y)))))

  (define (draw-bits board)
    (coord-iter
      (board-size board)
      (lambda (y x)
        (draw-bit y x (board-bit board y x)))))

  (define draw-bit
    (foreign-lambda* void ((int y) (int x) (int bit)) "
      mvwaddch(win, y*2 + 1, x*2 + 1, bit + '0');
      "))

  (define (draw-row-nums board-have board-want)
    (define size (board-size board-want))
    (let loop ((i 0))
      (draw-row-num
        size i
        (board-row-num board-want i))
      (if (< i (sub1 size))
          (loop (add1 i)))))

  (define (draw-col-nums board-have board-want)
    (define size (board-size board-want))
    (let loop ((i 0))
      (draw-col-num
        size i
        (board-col-num board-want i))
      (if (< i (sub1 size))
          (loop (add1 i)))))

  (define draw-row-num
    (foreign-lambda* void ((int size) (int i) (int num)) "
      int y = 2 * i + 1;
      int x = size * 2 + 1;
      mvwprintw(win, y, x, \"%d\", num);
      "))

  (define draw-col-num
    (foreign-lambda* void ((int size) (int i) (int num)) "
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

  (define-record cursor size y x)

  (define (move-cursor cursor dir)
    (define (valid? n)
      (and (>= n 0)
           (< n (cursor-size cursor))))
    (let* ((y (cursor-y cursor))
           (x (cursor-x cursor))
           (ny (match dir ('up (sub1 y))
                          ('down (add1 y))
                          (_ y)))
           (nx (match dir ('left (sub1 x))
                          ('right (add1 x))
                          (_ x))))
      (if (and (valid? ny)
               (valid? nx))
          (make-cursor (cursor-size cursor) ny nx)
          cursor)))

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

  (define key-up (foreign-value "KEY_UP" int))
  (define key-down (foreign-value "KEY_DOWN" int))
  (define key-left (foreign-value "KEY_LEFT" int))
  (define key-right (foreign-value "KEY_RIGHT" int))

  (define (read-input)
    (let loop ((ch (getch)))
      (cond
        ((= ch (char->integer #\q)) 'quit)
        ((= ch (char->integer #\Q)) 'quit)
        ((= ch key-up) 'up)
        ((= ch key-down) 'down)
        ((= ch key-left) 'left)
        ((= ch key-right) 'right)
        ((= ch (char->integer #\space)) 'flip)
        (else (loop (getch))))))

  (define getch
    (foreign-lambda* int () "
      C_return(wgetch(win));
      "))

)
