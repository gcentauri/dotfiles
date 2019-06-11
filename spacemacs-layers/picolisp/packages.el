;;; packages.el --- picolisp layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2018 Sylvain Benner & Contributors
;;
;; Author: Grant Shangreaux <shshoshin@protonmail.com>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;;; License: GPLv3

(defconst picolisp-packages
  '(
    ;; (inferior-picolisp :location local)
    org
    (picolisp-mode :location (recipe :fetcher github
                                     :repo "tj64/picolisp-mode"))
    smartparens
    ))

(defun picolisp/pre-init-org ()
  (spacemacs|use-package-add-hook org
    :post-config (add-to-list 'org-babel-load-languages '(picolisp . t))))

;; (defun picolisp/init-inferior-picolisp ()
  ;; (use-package inferior-picolisp))

(defun picolisp/init-picolisp-mode ()
  (use-package picolisp-mode
    :defer t
    :mode ("\\.l\\'" . picolisp-mode)
    :interpreter ("pil" . picolisp-mode)
    :init
    (progn
      (spacemacs/set-leader-keys-for-major-mode 'picolisp-mode
        ;; "d" 'picolisp-describe-symbol
        "'" 'run-picolisp
        "l" 'picolisp-load-file
        "d" 'picolisp-send-definition
        "D" 'picolisp-send-definition-and-go
        "e" 'picolisp-send-last-sexp
        "r" 'picolisp-send-region
        "R" 'picolisp-send-region-and-go
        ))
    (when picolisp-enable-transient-symbol-markup
      (add-hook 'picolisp-mode-hook (lambda () (tsm-mode))))
    ))

(defun picolisp/pre-init-smartparens ()
  (spacemacs|use-package-add-hook smartparens
    :post-config
    (sp-local-pair 'inferior-picolisp-mode "'" nil :actions nil)))

;;; packages.el ends here
