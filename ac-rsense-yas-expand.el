(require 'rsense)
(require 'yasnippet)

(defvar ac-rsense-yas-expand-working nil)
(defvar ac-rsense-yas-expand-class t)
(defadvice ac-complete (before ac-rsense-yas-expand-set-class)
  (setq ac-rsense-yas-expand-class (popup-item-property ac-selected-candidate 'summary)))
(ad-activate 'ac-complete)
(defun ac-rsense-yas-expand-try (&optional field)
   (setq ac-rsense-yas-expand-working t)
   (yas/expand field)
   (setq ac-rsense-yas-expand-working nil))

;override Rsense's auto-complete source
(ac-define-source rsense-yas
  '((candidates . ac-rsense-candidates)
   (prefix . "\\(?:\\.\\|::\\)\\(.*\\)")
   (requires . 0)
   (document . ac-rsense-documentation)
   (action . ac-rsense-yas-expand-try)
   (cache)))

;;override dropdown-list to replace keybind
(defun dropdown-list (candidates)
  (let ((selection)
        (temp-buffer))
    (save-window-excursion
      (unwind-protect
          (let ((candidate-count (length candidates))
                done key (selidx 0))
            (while (not done)
              (unless (dropdown-list-at-point candidates selidx)
                (switch-to-buffer (setq temp-buffer (get-buffer-create "*selection*"))
                                  'norecord)
                (delete-other-windows)
                (delete-region (point-min) (point-max))
                (insert (make-string (length candidates) ?\n))
                (goto-char (point-min))
                (dropdown-list-at-point candidates selidx))
              (setq key (read-key-sequence-vector ""))
              (cond ((and (>= (aref key 0) ?1)
                          (<= (aref key 0) (+ ?0 (min 9 candidate-count))))
                     (setq selection (- (aref key 0) ?1)
                           done      t))
                    ((member key `(,[?p] [?\M-p]))
                     (setq selidx (mod (+ candidate-count (1- (or selidx 0)))
                                       candidate-count)))
                    ((member key `(,[?n] [?\M-n] [?\C-i]))
                     (setq selidx (mod (1+ (or selidx -1)) candidate-count)))
                    ((member key `(,[?\C-m]))
                     (setq selection selidx
                           done      t))
                    (t (setq done t)))))
        (dropdown-list-hide)
        (and temp-buffer (kill-buffer temp-buffer)))
      selection)))

(provide 'ac-rsense-yas-expand)