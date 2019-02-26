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
    (board)
    (utils))

  #>
  #include <ncurses.h>

  static WINDOW *win;

  #define COLOR_NORMAL COLOR_PAIR(1)
  #define COLOR_CORRECT COLOR_PAIR(3)
  <#

  (define ui-setup
    (foreign-lambda* void () "
      initscr();
      start_color();
      noecho();
      cbreak();
      set_escdelay(0);
      init_pair(1, COLOR_WHITE,   COLOR_BLACK);
      init_pair(2, COLOR_YELLOW,  COLOR_BLACK);
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

  (define (draw-bits board)
    (let ((last (sub1 (board-size board))))
      (for y = 0 to last
        (for x = 0 to last
          (draw-bit y x (board-bit board y x))))))

  (define draw-bit
    (foreign-lambda* void ((int y) (int x) (int bit)) "
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
        wattron(win, COLOR_CORRECT);
      int y = 2 * i + 1;
      int x = size * 2 + 1;
      mvwprintw(win, y, x, \"%d\", num);
      wattron(win, COLOR_NORMAL);
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
        wattron(win, COLOR_CORRECT);
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
