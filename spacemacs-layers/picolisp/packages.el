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

;;; Commentary:

(defconst picolisp-packages
  '(
    (inferior-picolisp :location local)
    org
    picolisp-mode
    smartparens
    ))

(defun picolisp/pre-init-org ()
  (spacemacs|use-package-add-hook org
    :post-config (add-to-list 'org-babel-load-languages '(picolisp . t))))

(defun picolisp/init-inferior-picolisp ()
  (use-package inferior-picolisp))

(defun picolisp/init-picolisp-mode ()
  (use-package picolisp-mode
    :defer t
    :mode ("\\.l\\'" . picolisp-mode)
    :interpreter ("pil" . picolisp-mode)
    :init
    (progn
      (spacemacs/set-leader-keys-for-major-mode 'picolisp-mode
        "d" 'picolisp-describe-symbol
        "'" 'picolisp-repl
        ))))

(defun picolisp/pre-init-smartparens ()
  (spacemacs|use-package-add-hook smartparens
    :post-config
    (sp-local-pair 'picolisp-repl-mode "'" nil :actions nil)))

;;; packages.el ends here
