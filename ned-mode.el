;;; ned-mode.el --- Major mode to edit NED files in Emacs

;; Copyright (C) 2013 Dhaifallah Alwadani

;; Version: 0.1
;; Keywords: NED omnetpp INET  major mode
;; Author: Dhaifallah Alwadani <dalwadani@gmail.com>
;; URL: http://github.com/dalwadani/ned-mode
;; The code for indentation and tab behaviour is based on the work by Chris Wanstrath @ https://github.com/defunkt/coffee-mode
;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary

;; ## Indentation

;; ### TAB Theory

;; It goes like this: when you press `TAB`, we indent the line unless
;; doing so would make the current line more than two indentation levels
;; deepers than the previous line. If that's the case, remove all
;; indentation.

;; Consider this code, with point at the position indicated by the
;; caret:

;;     line1()
;;       line2()
;;       line3()
;;          ^

;; Pressing `TAB` will produce the following code:

;;     line1()
;;       line2()
;;         line3()
;;            ^

;; Pressing `TAB` again will produce this code:

;;     line1()
;;       line2()
;;     line3()
;;        ^

;; And so on. I think this is a pretty good way of getting decent
;; indentation with a whitespace-sensitive language.

;; ### Newline and Indent

;; We all love hitting `RET` and having the next line indented
;; properly. Given this code and cursor position:

;;     line1()
;;       line2()
;;       line3()
;;             ^

;; Pressing `RET` would insert a newline and place our cursor at the
;; following position:

;;     line1()
;;       line2()
;;       line3()

;;       ^

;; In other words, the level of indentation is maintained. This
;; applies to comments as well. Combined with the `TAB` you should be
;; able to get things where you want them pretty easily.

;; ### Indenters

;; `class`, `for`, `if`, and possibly other keywords cause the next line
;; to be indented a level deeper automatically.

;; For example, given this code and cursor position::

;;     class Animal
;;                 ^

;; Pressing enter would produce the following:

;;     class Animal

;;       ^

;; That is, indented a column deeper.

;; This also applies to lines ending in `->`, `=>`, `{`, `[`, and
;; possibly more characters.

;; So this code and cursor position:

;;     $('#demo').click ->
;;                        ^

;; On enter would produce this:

;;     $('#demo').click ->

;;       ^

;; Pretty slick.


;; command to comment/uncomment text
(defun ned-comment-dwim (arg)
  "Comment or uncomment current line or region in a smart way.
For detail, see `comment-dwim'."
  (interactive "*P")
  (require 'newcomment)
  (let (
        (comment-start "//") (comment-end "")
        )
    (comment-dwim arg)))


(defvar ned-mode-map
  (let ((map (make-sparse-keymap)))
    ;; key bindings
    (define-key map [remap newline-and-indent] 'ned-newline-and-indent)
    (define-key map "\C-m" 'ned-newline-and-indent)
    (define-key map "\177" 'ned-dedent-line-backspace)
    (define-key map (kbd "C-c C-<") 'ned-indent-shift-left)
    (define-key map (kbd "C-c C->") 'ned-indent-shift-right)
    (define-key map (kbd "<backtab>") 'ned-indent-shift-left)
    map)
  "Keymap for ned major mode.")


;;
;; Indentation
;;

;;; The theory is explained in the README.

(defun ned-indent-line ()
  "Indent current line as ned."
  (interactive)

  (if (= (point) (point-at-bol))
      (insert-tab)
    (save-excursion
      (let ((prev-indent (ned-previous-indent))
            (cur-indent (current-indentation)))
        ;; Shift one column to the left
        (beginning-of-line)
        (insert-tab)

        (when (= (point-at-bol) (point))
          (forward-char tab-width))

        ;; We're too far, remove all indentation.
        (when (> (- (current-indentation) prev-indent) tab-width)
          (backward-to-indentation 0)
          (delete-region (point-at-bol) (point)))))))

(defun ned-previous-indent ()
  "Return the indentation level of the previous non-blank line."
  (save-excursion
    (forward-line -1)
    (if (bobp)
        0
      (progn
        (while (and (looking-at "^[ \t]*$") (not (bobp))) (forward-line -1))
        (current-indentation)))))

(defun ned-newline-and-indent ()
  "Insert a newline and indent it to the same level as the previous line."
  (interactive)

  ;; Remember the current line indentation level,
  ;; insert a newline, and indent the newline to the same
  ;; level as the previous line.
  (let ((prev-indent (current-indentation)) (indent-next nil))
    (delete-horizontal-space t)
    (newline)
    (insert-tab (/ prev-indent tab-width))

    ;; We need to insert an additional tab because the last line was special.
    (when (ned-line-wants-indent)
      (insert-tab)))

  ;; Last line was a comment so this one should probably be,
  ;; too. Makes it easy to write multi-line comments (like the one I'm
  ;; writing right now).
  (when (ned-previous-line-is-comment)
    (insert "// ")))

(defun ned-dedent-line-backspace (arg)
  "Unindent to increment of `tab-width' with ARG==1 when
called from first non-blank char of line.

Delete ARG spaces if ARG!=1."
  (interactive "*p")
  (if (and (= 1 arg)
           (= (point) (save-excursion
                        (back-to-indentation)
                        (point)))
           (not (bolp)))
      (let ((extra-space-count (% (current-column) tab-width)))
        (backward-delete-char-untabify
         (if (zerop extra-space-count)
             tab-width
           extra-space-count)))
    (backward-delete-char-untabify arg)))

;; Indenters help determine whether the current line should be
;; indented further based on the content of the previous line. If a
;; line starts with `class', for instance, you're probably going to
;; want to indent the next line.

(defvar ned-indenters-bol '("class" "for" "if" "try" "while")
  "Keywords or syntax whose presence at the start of a line means the
next line should probably be indented.")

(defun ned-indenters-bol-regexp ()
  "Builds a regexp out of `ned-indenters-bol' words."
  (regexp-opt ned-indenters-bol 'words))

(defvar ned-indenters-eol '(?> ?{ ?\[)
  "Single characters at the end of a line that mean the next line
should probably be indented.")

(defun ned-line-wants-indent ()
  "Return t if the current line should be indented relative to the
previous line."
  (interactive)

  (save-excursion
    (let ((indenter-at-bol) (indenter-at-eol))
      ;; Go back a line and to the first character.
      (forward-line -1)
      (backward-to-indentation 0)

      ;; If the next few characters match one of our magic indenter
      ;; keywords, we want to indent the line we were on originally.
      (when (looking-at (ned-indenters-bol-regexp))
        (setq indenter-at-bol t))

      ;; If that didn't match, go to the back of the line and check to
      ;; see if the last character matches one of our indenter
      ;; characters.
      (when (not indenter-at-bol)
        (end-of-line)

        ;; Optimized for speed - checks only the last character.
        (let ((indenters ned-indenters-eol))
          (while indenters
            (if (and (char-before) (/= (char-before) (car indenters)))
                (setq indenters (cdr indenters))
              (setq indenter-at-eol t)
              (setq indenters nil)))))

      ;; If we found an indenter, return `t'.
      (or indenter-at-bol indenter-at-eol))))

(defun ned-previous-line-is-comment ()
  "Return t if the previous line is a ned comment."
  (save-excursion
    (forward-line -1)
    (ned-line-is-comment)))

(defun ned-line-is-comment ()
  "Return t if the current line is a ned comment."
  (save-excursion
    (backward-to-indentation 0)
    (= (char-after) (string-to-char "//"))))
(defun ned-indent-shift-amount (start end dir)
  "Compute distance to the closest increment of `tab-width'."
  (let ((min most-positive-fixnum) rem)
    (save-excursion
      (goto-char start)
      (while (< (point) end)
        (let ((current (current-indentation)))
          (when (< current min) (setq min current)))
        (forward-line))
      (setq rem (% min tab-width))
      (if (zerop rem)
          tab-width
        (cond ((eq dir 'left) rem)
              ((eq dir 'right) (- tab-width rem))
              (t 0))))))

(defun ned-indent-shift-left (start end &optional count)
  "Shift lines contained in region START END by COUNT columns to the left.
If COUNT is not given, indents to the closest increment of
`tab-width'. If region isn't active, the current line is
shifted. The shifted region includes the lines in which START and
END lie. An error is signaled if any lines in the region are
indented less than COUNT columns."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end) current-prefix-arg)
     (list (line-beginning-position) (line-end-position) current-prefix-arg)))
  (let ((amount (if count (prefix-numeric-value count)
                  (ned-indent-shift-amount start end 'left))))
    (when (> amount 0)
      (let (deactivate-mark)
        (save-excursion
          (goto-char start)
          ;; Check that all lines can be shifted enough
          (while (< (point) end)
            (if (and (< (current-indentation) amount)
                     (not (looking-at "[ \t]*$")))
                (error "Can't shift all lines enough"))
            (forward-line))
          (indent-rigidly start end (- amount)))))))

(add-to-list 'debug-ignored-errors "^Can't shift all lines enough")

(defun ned-indent-shift-right (start end &optional count)
  "Shift lines contained in region START END by COUNT columns to the right.
if COUNT is not given, indents to the closest increment of
`tab-width'. If region isn't active, the current line is
shifted. The shifted region includes the lines in which START and
END lie."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end) current-prefix-arg)
     (list (line-beginning-position) (line-end-position) current-prefix-arg)))
  (let (deactivate-mark
        (amount (if count (prefix-numeric-value count)
                  (ned-indent-shift-amount start end 'right))))
    (indent-rigidly start end amount)))

;;
;;
;; Commands
;;



;; syntax table
(defvar ned-syntax-table nil "Syntax table for `ned-mode'.")
(setq ned-syntax-table
      (let ((synTable (make-syntax-table)))

	;; C++ style comment “// …” 
	(modify-syntax-entry ?\/ ". 12b" synTable)
	(modify-syntax-entry ?\n "> b" synTable)
        synTable))



;; define several class of keywords
(setq NED-keywords '("gates"  "parameters" "connections" "submodules" "inet" "net" "ned" "default" "if" "for" "<--") )
(setq NED-types '("network"  "IPv4NetworkConfigurator" "simple" "module" "int" "bool" "string"))
(setq NED-constants '("true" "false"))
(setq NED-events '("display"))
(setq NED-functions '("package" "extends" "import" "like"))



;; create the regex string for each class of keywords
(setq NED-keywords-regexp (regexp-opt NED-keywords 'words))
(setq NED-type-regexp (regexp-opt NED-types 'words))
(setq NED-constant-regexp (regexp-opt NED-constants 'words))
(setq NED-event-regexp (regexp-opt NED-events 'words))
(setq NED-functions-regexp (regexp-opt NED-functions 'words))
(setq NED-functions-regexp (regexp-opt NED-functions 'words))
(setq NED-operators-regexp "<?-->?\\|\\.\\.\\|=")
;; clear memory
(setq NED-keywords nil)
(setq NED-types nil)
(setq NED-constants nil)
(setq NED-events nil)
(setq NED-functions nil)


;; create the list for font-lock.
;; each class of keyword is given a particular face
(setq NED-font-lock-keywords
  `(
    (,NED-type-regexp . font-lock-type-face)
    (,NED-constant-regexp . font-lock-constant-face)
    (,NED-event-regexp . font-lock-builtin-face)
    (,NED-functions-regexp . font-lock-function-name-face)
    (,NED-keywords-regexp . font-lock-keyword-face)
    (,NED-operators-regexp . font-lock-keyword-face)
    ;; note: order above matters.

))






;; define the mode
(define-derived-mode ned-mode fundamental-mode
  "ned mode"
  "Major mode for editing NED (NEtwork Description)…"
  :syntax-table ned-syntax-table
  ;; code for syntax highlighting
  (setq font-lock-defaults '((NED-font-lock-keywords)))

  ;; clear memory
  (setq NED-keywords-regexp nil)
  (setq NED-types-regexp nil)
  (setq NED-constants-regexp nil)
  (setq NED-events-regexp nil)
  (setq NED-functions-regexp nil)
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'indent-line-function) #'ned-indent-line)



  ;; no tabs
  (setq indent-tabs-mode nil))



;; setup files ending in “.ned” to open in ned-mode
(add-to-list 'auto-mode-alist '("\\.ned\\'" . ned-mode))
(provide 'ned-mode)
