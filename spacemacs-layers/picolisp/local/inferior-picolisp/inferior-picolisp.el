;; * inferior-picolisp.el --- picolisp repl in a buffer
;; ** MetaData
;;   :PROPERTIES:
;;   :copyright: Guillermo_R._Palavecino Thorsten_Jolitz
;;   :copyright-since: 2009
;;   :version:  1.2
;;   :licence:  GPL2+
;;   :licence-url: http://www.gnu.org/licenses/
;;   :part-of-emacs: no
;;   :git-repo: https://github.com/tj64/iorg
;;   :git-clone: git@github.com:tj64/iorg.git
;;   :authors: Guillermo_R._Palavecino Thorsten_Jolitz
;;   :contact: <grpala@gmail.com> <tjolitz@gmail.com>
;;   :inspiration:  cmuscheme.el
;;   :keywords: emacs picolisp comint repl iorg
;;   :END:

;; ** Commentary

;; For comments, bug reports, questions, etc use the picolisp mailing list,
;; the #picolisp channel on irc.freenode.net, or the author's emails given
;; above.

;; * Requires

(require 'comint)

;; * Mode definitions
;; ** Inferior Picolisp Mode

(define-derived-mode inferior-picolisp-mode comint-mode "Inferior Picolisp"
  "Major mode for interacting with an inferior Picolisp process.

The following commands are available:
\\{inferior-picolisp-mode-map}

An Picolisp process can be fired up with 'M-x run-picolisp'.

Customization: Entry to this mode runs the hooks on `comint-mode-hook' and
`inferior-picolisp-mode-hook' (in that order).

You can send text to the inferior Picolisp process from other
buffers containing Picolisp source.

 - `switch-to-picolisp' switches the current buffer to the
   Picolisp process buffer.

 - `picolisp-send-definition' sends the current definition to the
   Picolisp process.

 - `picolisp-send-region' sends the current region to the
   Picolisp process.

 - `picolisp-send-definition-and-go' and
   `picolisp-send-region-and-go' switch to the Picolisp process
   buffer after sending their text.

For information on running multiple processes in multiple buffers, see
documentation for variable `picolisp-buffer'.

Commands:

'Return' after the end of the process' output sends the text from
the end of process to point.

'Return' before the end of the process' output copies the sexp
ending at point to the end of the process' output, and sends it.

'Delete' converts tabs to spaces as it moves back.

'Tab' indents for Picolisp; with argument, shifts rest of
expression rigidly with the current line.

'C-M-q' does Tab on each line starting within following
expression.

Paragraphs are separated only by blank lines.  Semicolons start comments.
If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it."
  ;; Customize in inferior-picolisp-mode-hook
  (setq comint-prompt-regexp "^[^\n:?!]*[?!:]+ *")
  (setq comint-prompt-read-only nil)
  (setq comint-input-filter (function picolisp-input-filter))
  (setq comint-get-old-input (function picolisp-get-old-input))
  (setq mode-line-process '(":%s"))
  (setq comint-input-ring-file-name "~/.pil_history") )

;; * Hooks
;; * Variables
;; ** Vars

(defvar picolisp-emacs-as-editor-p nil
  "If non-nil, use `eedit.l' instead of `edit.l'.")

(defvar picolisp-local-program-name "./pil +")
;; (defvar picolisp-process-number 0)

(defvar picolisp-program-name "pil +"
  "The name of the program used to run Picolisp." )

(defvar picolisp-buffer)

(defvar picolisp-prev-load-dir/file nil
  "Caches the last (directory . file) pair.
Caches the last pair used in the last `picolisp-load-file' command.
Used for determining the default in the next one." )


(defvar picolisp-buffer nil "*The current picolisp process buffer.

MULTIPLE PROCESS SUPPORT
==================================================================

inferior-picolisp.el supports, in a fairly simple fashion,
running multiple Picolisp processes. To run multiple Picolisp
processes, you start the first up with \\[run-picolisp]. It will
be in a buffer named *picolisp*. Rename this buffer with
\\[rename-buffer]. You may now start up a new process with
another \\[run-picolisp]. It will be in a new buffer, named
*picolisp*. You can switch between the different process buffers
with \\[switch-to-buffer].

Commands that send text from source buffers to Picolisp processes
-- like `picolisp-send-definition' -- have to choose a process to
send to, when you have more than one Picolisp process around.
This is determined by the global variable `picolisp-buffer'.
Suppose you have three inferior Picolisps running:

    Buffer      Process
    foo         picolisp
    bar         picolisp<2>
    *picolisp*  picolisp<3>

If you do a \\[picolisp-send-definition-and-go] command on some
Picolisp source code, what process do you send it to?

- If you're in a process buffer (foo, bar, or *picolisp*),
  you send it to that process.
- If you're in some other buffer (e.g., a source file), you
  send it to the process attached to buffer `picolisp-buffer'.

This process selection is performed by function `picolisp-proc'.

Whenever \\[run-picolisp] fires up a new process, it resets
`picolisp-buffer' to be the new process's buffer. If you only run
one process, this will do the right thing. If you run multiple
processes, you can change `picolisp-buffer' to another process
buffer with \\[set-variable].

More sophisticated approaches are, of course, possible. If you
find yourself needing to switch back and forth between multiple
processes frequently, you may wish to consider ilisp.el, a
larger, more sophisticated package for running inferior Lisp and
Picolisp processes. The approach taken here is for a minimal,
simple implementation. Feel free to extend it." )

;; ** Consts

(defconst inferior-picolisp-version "1.2"
  "Verion-number of library")

;; ** Customs
;; *** Custom Groups

(defgroup picolisp nil
  "Run an Picolisp process in a buffer."
  :group 'picolisp )

;; *** Custom Vars

(defcustom inferior-picolisp-mode-hook nil
  "*Hook for customizing inferior-picolisp mode."
  :type 'hook
  :group 'picolisp )

(defcustom inferior-picolisp-load-hook nil
  "This hook is run when inferior-picolisp is loaded in.
This is a good place to put keybindings."
  :type 'hook
  :group 'picolisp )

(defcustom inferior-picolisp-filter-regexp "\\`\\s *\\S ?\\S ?\\s *\\'"
  "*Input matching this regexp are not saved on the history list.
Defaults to a regexp ignoring all inputs of 0, 1, or 2 letters."
  :type 'regexp
  :group 'picolisp )

(defcustom picolisp-source-modes '(picolisp-mode)
  "*Used to determine if a buffer contains Picolisp source code.
If it's loaded into a buffer that is in one of these major modes,
it's considered a picolisp source file by `picolisp-load-file'.  Used by
these commands to determine defaults."
  :type '(repeat function)
  :group 'picolisp )

;; * Functions
;; ** Non-interactive Functions

;; *** Utilities 

(defun picolisp-get-old-input ()
  "Snarf the sexp ending at point."
  (save-excursion
    (let ((end (point)))
      (backward-sexp)
      (buffer-substring (point) end) ) ) )

;; *** Filters

(defun picolisp-input-filter (str)
  "Don't save anything matching `inferior-picolisp-filter-regexp'."
  (not (string-match inferior-picolisp-filter-regexp str)) )

;; *** Deal with PicoLisp Line Editor

(defun picolisp-get-editor-info ()
  "Find out if Emacs is used as editor."
  (let* ((editor-file (expand-file-name "editor" "~/.pil/"))
         (editor-orig-file (expand-file-name "editor-orig" "~/.pil/"))
         (ed-file
          (cond
           ((file-exists-p editor-file) editor-file)
           ((file-exists-p editor-orig-file) editor-orig-file)
           (t nil))))
    (when ed-file
      (with-current-buffer (find-file-noselect ed-file)
        (goto-char (point-min))
        (if (re-search-forward "eedit" nil 'NOERROR)
            (setq picolisp-emacs-as-editor-p t)
           (setq picolisp-emacs-as-editor-p nil))
        (kill-buffer)))))

(defun picolisp-disable-line-editor ()
  "Disable inbuild PicoLisp line-editor.
The line-editor is not needed when PicoLisp is run as Emacs subprocess."
  (let ((pil-tmp-dir (expand-file-name "~/.pil/")))
    ;; renaming of existing editor file
    (cond
     ;; abnormal condition, something went wrong before
     ((and
       (member "editor" (directory-files pil-tmp-dir))
       (member "editor-orig" (directory-files pil-tmp-dir)))
      (let ((ed-size
             (nth
              7
              (file-attributes
               (expand-file-name "editor" pil-tmp-dir))))
            (ed-orig-size
             (nth
              7
              (file-attributes
               (expand-file-name "editor-orig"  pil-tmp-dir)))))
        (if (or (= ed-size 0)
                (<= ed-size ed-orig-size))
            (delete-file
             (expand-file-name "editor" pil-tmp-dir))
        (rename-file
         (expand-file-name "editor" pil-tmp-dir)
         (expand-file-name "editor-orig" pil-tmp-dir)
         'OK-IF-ALREADY-EXISTS))))
     ;; normal condition, only editor file exists
     ((member "editor" (directory-files pil-tmp-dir ))
      (rename-file
          (expand-file-name "editor" pil-tmp-dir)
          (expand-file-name "editor-orig" pil-tmp-dir))))
    ;; after renaming, create new empty editor file
    (with-current-buffer
        (find-file-noselect
         (expand-file-name "editor" pil-tmp-dir))
      (erase-buffer)
      (save-buffer)
      (kill-buffer))))

(defun picolisp-reset-line-editor ()
  "Reset inbuild PicoLisp line-editor to original state."
  (let ((pil-tmp-dir (expand-file-name "~/.pil/")))
    (if (member "editor-orig" (directory-files pil-tmp-dir))
        (rename-file
         (expand-file-name "editor-orig" pil-tmp-dir)
         (expand-file-name "editor" pil-tmp-dir)
         'OK-IF-ALREADY-EXISTS)
      (delete-file
       (expand-file-name "editor" pil-tmp-dir)))))

; ** Commands

;; *** Start REPL

;;;###autoload
(defun run-picolisp (cmd)
  "Run an inferior Picolisp process, input and output via buffer `*picolisp*'.
If there is a process already running in `*picolisp*', switch to that buffer.
With argument, allows you to edit the command line (default is value
of `picolisp-program-name').
Runs the hook `inferior-picolisp-mode-hook' \(after the `comint-mode-hook'
is run).
\(Type \\[describe-mode] in the process buffer for a list of commands.)"

  (interactive (list (if current-prefix-arg
                         (read-string "Run Picolisp: " picolisp-program-name)
                       picolisp-program-name ) ) )
  (when (not (comint-check-proc "*picolisp*"))
    (let ((cmdlist (split-string cmd)))
      (picolisp-get-editor-info)
      (picolisp-disable-line-editor)
      (set-buffer
       (apply 'make-comint
              "picolisp"
              (car cmdlist)
              nil
              ;; hack for multi-word PicoLisp arguments:
              ;; separate them with '_XXX_' in the 'cmd' arg
              ;; instead of blanks
              (mapcar
               (lambda (--arg)
                 (replace-regexp-in-string
                  "_XXX_" " " --arg))
             (if picolisp-emacs-as-editor-p
                 (cons "@lib/eedit.l" (cdr cmdlist))
               (cons "@lib/edit.l" (cdr cmdlist)) ) ) ) )
      (picolisp-reset-line-editor)
      (inferior-picolisp-mode) ) )
  (setq picolisp-program-name cmd)
  (setq picolisp-buffer "*picolisp*")
  (pop-to-buffer "*picolisp*") )
;;;###autoload (add-hook 'same-window-buffer-names "*picolisp*")


;; * Run hooks and provide
(run-hooks 'inferior-picolisp-load-hook)

(provide 'inferior-picolisp)
