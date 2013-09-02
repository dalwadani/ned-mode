;;; ned-mode.el --- Major mode to edit NED files in Emacs

;; Copyright (C) 2013 Dhaifallah Alwadani

;; Version: 0.1
;; Keywords: NED omnetpp INET  major mode
;; Author: Dhaifallah Alwadani <dalwadani@gmail.com>
;; URL: http://github.com/dalwadani/ned-mode

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

;; define several class of keywords
(setq NED-keywords '("parameters:" "import") )
(setq NED-types '("network" "channel"))
(setq NED-constants '("pppg"))
(setq NED-events '("@display"))
(setq NED-functions '("<-->"))



;; create the regex string for each class of keywords
(setq NED-keywords-regexp (regexp-opt NED-keywords 'words))
(setq NED-type-regexp (regexp-opt NED-types 'words))
(setq NED-constant-regexp (regexp-opt NED-constants 'words))
(setq NED-event-regexp (regexp-opt NED-events 'words))
(setq NED-functions-regexp (regexp-opt NED-functions 'words))

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
    ;; note: order above matters. “NED-keywords-regexp” goes last because
    ;; otherwise the keyword “state” in the function “state_entry”
    ;; would be highlighted.
))



;; define the mode
(define-derived-mode ned-mode fundamental-mode
  "ned mode"
  "Major mode for editing NED (NEtwork Description)…"

  ;; code for syntax highlighting
  (setq font-lock-defaults '((NED-font-lock-keywords)))

  ;; clear memory
  (setq NED-keywords-regexp nil)
  (setq NED-types-regexp nil)
  (setq NED-constants-regexp nil)
  (setq NED-events-regexp nil)
  (setq NED-functions-regexp nil)
)


(provide 'ned-mode)
