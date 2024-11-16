;;; exwm-firefox.el --- Firefox tweaked for EXWM   -*- lexical-binding: t;-*-

;; Copyright (C) 2024  Ethan Moss

;; Author: Ethan Moss <cywinskimoss@gmail.com>
;; Keywords: exwm web browser

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Firefox tweaked for EXWM

;;; Code:
(require 'consult)

;;;; --- Variables ---

(defvar sitesearch-browser nil
  "The browser to which is used to open the given URLs")

(defvar sitesearch-browser-args nil
  "Arguments for your browser of choice when launching.
This could be personal preferences such as opening in a new tab or window")

(defvar sitesearch-search nil
  "The history list for sitesearch bookmark functions.")

(defvar sitesearch-bookmarks nil
  "List of all the bookmarks")

(defvar sitesearch--history '()
  "url history for sitesearch")

(defvar sitesearch--search-terms-history nil
  "history var for search terms")

(defvar sitesearch--source-recent
  `( :name     "Recent"
     :narrow   ?r
     :category recents
     :face     consult-buffer
	 :items    ,sitesearch--history
	 :annotate (lambda (candidate) (plist-get candidate :url))
	 :history  sitesearch--history)
  "TODO docstring")

(defvar sitesearch--source-bookmark
  `( :name     "Bookmark"
     :narrow   ?m
     :category bookmarks
     :face     consult-bookmark
     :items    ,sitesearch-bookmarks
	 :annotate (lambda (candidate) (plist-get candidate :url)))
  "TODO docstring")

(defvar sitesearch--source-search
  `( :name     "Search"
     :narrow   ?s
 	 :hidden   t
     :category search
     :face     consult-file
     :items    ,sitesearch-search
	 :annotate (lambda (candidate) (plist-get candidate :url)))
  "TODO docstring")

(defcustom sitesearch--sources
  '( sitesearch--source-search
	 sitesearch--source-recent
	 sitesearch--source-bookmark)
  "List of sources used by ‘sitesearch’."
  :type '(repeat symbol))


;;;; --- Functions ---

(defun sitesearch-interactive ()
  "The interactive function for sitesearch"
  (interactive)
  (let* ((selected (consult--multi sitesearch--sources
								   :prompt "Browse: "
								   :sort nil)))
	(sitesearch--select-action selected)))

(defun sitesearch--select-action (selected)
  "Open the given url"
  ;; start a new process with the users browser of choice
  ;; specific settings such as "as a tab" or "in new window" should be passed in
  ;; this way we can have extra user control
  (let* ((selected-plist (car selected))
		 (selected-url (plist-get selected-plist :url))
		 (selected-cons (cdr selected)))
	(if (and (string-equal (plist-get selected-cons :name) "Search")
			 (plist-get selected-cons :match))
		(sitesearch--search-with-url selected-url)
	  (sitesearch--browse-with-url selected-url))))

(defun sitesearch--search-with-url (url)
  "Search the website with given search terms given by the URL"
  (let* ((search-terms (sitesearch--get-search-terms))
		(url-and-terms (replace-regexp-in-string "%s" search-terms url)))
	(sitesearch--browse-with-url url-and-terms)))

(defun sitesearch--browse-with-url (url)
  "Browse the website given by the URL"
  (unless sitesearch-browser
	(user-error "Please modify ‘sitesearch-browser’ with your chosen browser"))
  (shell-command (format "%s %s %s"
						 sitesearch-browser
						 sitesearch-browser-args
						 url))
  (add-to-history 'sitesearch--history url))

(defun sitesearch--get-search-terms ()
  "ask a user for what they want to search for."
  (replace-regexp-in-string " " "+" (completing-read "Search terms: "
													   nil nil nil nil
													   sitesearch--search-terms-history)))

(provide 'sitesearch)
;;; sitesearch.el ends here
