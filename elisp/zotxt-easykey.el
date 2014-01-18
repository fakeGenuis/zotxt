(require 'zotxt)

(defvar zotxt-easykey-regex
  "[@{]\\([[:alnum:]:]+\\)")

(defvar zotxt-easykey-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(control c) (z) (o)] 'zotxt-easykey-select-item-at-point)
    map))

(defun zotxt-easykey-at-point-match ()
  (if (not (looking-at zotxt-easykey-regex))
      (save-excursion
        ;; always try to back up one char
        (backward-char)
        (while (and (not (looking-at zotxt-easykey-regex))
                    (looking-at "[[:alnum:]:]"))
          (backward-char))
        (looking-at zotxt-easykey-regex))))

(defun zotxt-easykey-at-point ()
  "Return the value of the easykey at point. Easykey must start
with a @ or { to be recognized, but this will *not* be returned."
  (save-excursion
    (if (zotxt-easykey-at-point-match)
        (match-string 1)
      nil)))
  
(defun zotxt-easykey-complete-at-point ()
  (save-excursion
    (if (not (zotxt-easykey-at-point-match))
        nil
      (let ((start (match-beginning 0))
            (end (match-end 0))
            (key (match-string 1)))
        (let* ((url (format "http://localhost:23119/zotxt/complete?easykey=%s" key))
               (response (zotxt-url-retrieve url)))
          (if (null response)
              nil
            (let ((completions (mapcar (lambda (k) (format "@%s" k)) response)))
              (list start end completions))))))))

(defun zotxt-easykey-get-item-id-at-point ()
  "Return the Zotero ID of the item referred to by the easykey at
point, or nil."
  (save-excursion
    (let ((key (zotxt-easykey-at-point)))
      (if (null key)
          nil
        (let* ((url (format "http://localhost:23119/zotxt/items?format=key&easykey=%s" key))
               (response (zotxt-url-retrieve url)))
          (if (null response)
              nil
            (elt response 0)))))))

(defun zotxt-easykey-get-item-easykey (key)
  (zotxt-url-retrieve
   (format "http://localhost:23119/zotxt/items?key=%s&format=easykey" key)))

(defun zotxt-easykey-insert ()
  "Prompt for a search string and insert an easy key."
  (interactive)
  (let ((key (zotxt-select)))
    (insert (format "@%s" (elt (zotxt-easykey-get-item-easykey key) 0)))))

(defun zotxt-easykey-select-item-at-point ()
  "Select the item referred to by the easykey at point in Zotero."
  (interactive)
  (let ((item-id (zotxt-easykey-get-item-id-at-point)))
    (if item-id
        (browse-url (format "zotero://select/items/%s" item-id))
      (error "No item found!"))))

(define-minor-mode zotxt-easykey-mode
  "Toggle zotxt-easykey-mode.
With no argument, this command toggles the mode.
Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode.

This is a minor mode for managing your easykey citations,
including completion."
  :init-value nil
  :lighter "Zotxt Easykey"
  :keymap zotxt-easykey-mode-map
  (if zotxt-easykey-mode
      (add-to-list 'completion-at-point-functions 'zotxt-easykey-complete-at-point)
    (setq-local completion-at-point-functions (remove 'zotxt-easykey-complete-at-point completion-at-point-functions))))

(provide 'zotxt-easykey)
