;;; use-package-ensure-git-repo.el --- auto install packages from git repository  -*- lexical-binding: t; -*-

;; Author: Jian Wang <leuven65@gmail.com>
;; URL: https://github.com/leuven65/use-package-ensure-git-repo
;; Version: 0.1.0
;; Keywords: use-package, git, github

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;

;;; Code:

(require 'use-package)

(defvar use-package-ensure-git-repo-always-update t
  "Update the git repo by default")

(defun use-package-ensure-git-repo-clone-git-repo (repo-url local-dir)
  "clone git repo"
  (let ((cmd (format "git clone --depth 1 '%s' '%s'"
                     repo-url local-dir)))
    (message "Try to clone: %s" cmd)
    (call-process-shell-command cmd)))

(defun use-package-ensure-git-repo-update-git-repo (local-dir)
  "git pull"
  (let* ((dir (use-package-ensure-git-repo-get-package-dir local-dir))
         (cmd (format "cd '%s' && git pull" dir)))
    (message "Try to update repo '%s'" dir)
    (call-process-shell-command cmd)))

(defun use-package-ensure-git-repo-get-package-dir (dir-name)
  (expand-file-name (concat "packages/" dir-name)
                    user-emacs-directory))

(defun use-package-ensure-git-repo-process (repo-url dir-name)
  "clone or update git repo to ~/.emacs.d/packages/dir-name"
  (let ((local-dir (use-package-ensure-git-repo-get-package-dir dir-name))
        (autoload-filename (concat dir-name "-autoloads.el"))
        (bool-need-compile nil))
    (if (file-exists-p (expand-file-name ".git" local-dir))
        (when use-package-ensure-git-repo-always-update
          ;; update git repo
          (use-package-ensure-git-repo-update-git-repo local-dir)
          (setq bool-need-compile t))
      ;; clone git repo
      (use-package-ensure-git-repo-clone-git-repo repo-url local-dir)
      (setq bool-need-compile t))
    (when bool-need-compile
      ;; delete autoloads file
      (delete-file (expand-file-name autoload-filename local-dir) nil)
      ;; Generate autoloads file
      (ignore-errors
        (package-generate-autoloads dir-name local-dir))
      ;; force to compile all *.el files
      (byte-recompile-directory local-dir 0 t))
    ;; load the autoload file
    (add-to-list 'load-path local-dir)
    (load autoload-filename)
    )
  )

;;;###autoload
(defun use-package-normalize/:ensure-git-repo (_name-symbol keyword args)
  "Turn `arg' into a list of cons-es of (`git-repo-rul' . `local-dir-name')."
  (use-package-only-one (symbol-name keyword) args
    (lambda (_label arg)
      (cond
       ((consp arg) arg)
       ((stringp arg) (cons arg (symbol-name _name-symbol)))
       ))))

;;;###autoload
(defun use-package-handler/:ensure-git-repo (name _keyword arg rest state)
  "Execute the handler for `:ensure-git-reop' keyword in `use-package'."
  (let ((body (use-package-process-keywords name rest state)))
    (use-package-concat
     `((use-package-ensure-git-repo-process ,(car arg) ,(cdr arg)))
     body)))

;; let this keyword to be the first to be processed
(add-to-list 'use-package-keywords :ensure-git-repo)

(provide 'use-package-ensure-git-repo)

;;; use-package-ensure-git-repo.el ends here
