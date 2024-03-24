{ config, pkgs, ... }:

{
  home.stateVersion = "23.11";
  programs.home-manager.enable = true;  # Let Home Manager install and manage itself.

  home.username = "debian";
  home.homeDirectory = "/home/debian";

  home.sessionVariables = {
    EDITOR = "emacs";
  };

  programs.emacs = {
    enable = true;
    extraPackages = epkgs: with epkgs; [
      magit
      company
      vertico
      orderless
      lsp-mode
      nix-mode
      flycheck
      rustic
      toml-mode
      direnv
      which-key
      expand-region
      key-chord
      multiple-cursors
    ];
  };

  home.file.".emacs.d/init.el".text = ''
(setq indent-tabs-mode nil
      tab-width 2
      dired-recursive-deletes 'always
      dired-recursive-copies 'always
      initial-major-mode 'fundamental-mode
      inhibit-startup-message t
      ring-bell-function 'ignore)

(setq-default case-fold-search t
              case-replace t ;; should replace keep case?
              compilation-scroll-output t
              compilation-ask-about-save nil
              truncate-lines t
              make-backup-files t
              backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
              delete-old-versions t
              auto-save-file-name-transforms `(("\\`/[^/]*:\\([^/]*/\\)*\\([^/]*\\)\\'" ,temporary-file-directory t)
                                               (".*" ,(expand-file-name "backups" user-emacs-directory) t))
              create-lockfiles nil)

(savehist-mode)
(transient-mark-mode t)
(delete-selection-mode t)
(direnv-mode)
(global-company-mode)
(global-set-key (kbd "M-m") 'company-complete)
(which-key-mode)
(vertico-mode)
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles basic partial-completion))))

;; ---------------------

(setq lsp-nix-nil-formatter ["nixpkgs-fmt"])
(add-hook 'nix-mode-hook 'lsp-deferred)

;; ---------------------

(defun rk/rustic-mode-hook ()
  (flycheck-mode)
  (setq-local lsp-inlay-hint-enable t)
  (add-hook 'before-save-hook 'lsp-format-buffer nil t)
  (setq-local buffer-save-without-query t))

(add-hook 'rustic-mode-hook 'rk/rustic-mode-hook)

;; ---------------------

(defun rk/move-beginning-of-line (arg)
  "move either at `bol' or when already there then in front of
  the first non-whitespace char"
  (interactive "p")
  (let ((p (point)))
    (back-to-indentation)
    (when (= p (point))
      (move-beginning-of-line arg))))

(global-set-key (kbd "C-a") 'rk/move-beginning-of-line)

(key-chord-mode 1)
(key-chord-define-global "vm" 'er/expand-region)
(key-chord-define-global "dh" 'er/contract-region)

;; --------------------

(defun rk/mc-cursors-merge ()
  "Removes cursors that are at the same position"
  (interactive)
  (let ((cursors (seq-sort-by (lambda (o) (overlay-start o)) '< (mc/all-fake-cursors))))
    (while (= (point) (overlay-start (car cursors)))
      (mc/remove-fake-cursor (car cursors))
      (setq cursors (cdr cursors)))
    (let ((last-cursor (car cursors)))
      (dolist (cursor (cdr cursors))
	(let ((pos (overlay-start cursor)))
	  (if (or (= (point) pos) (= (overlay-start last-cursor) pos))
	      (mc/remove-fake-cursor cursor)
	    (setq last-cursor cursor)))))
    (mc/maybe-multiple-cursors-mode)))

(require 'cl-lib)
(defun rk/mc-mark-next-like-this-and-cycle-forward (arg)
  "Like `mc/mark-next-like-this' but also forward-cycles the cursor."
  (interactive "p")
  (cl-flet ((recenter () nil))
   (when (< arg 0) (mc/cycle-backward))
   (mc/mark-next-like-this arg)
   (rk/mc-cursors-merge)
   (when (>= arg 0) (mc/cycle-forward))))

(defun rk/mc-mark-previous-like-this-and-cycle-backward (arg)
  "Like `mc/mark-previous-like-this' but also backward-cycles the cursor."
  (interactive "p")
  (cl-flet ((recenter () nil))
   (when (< arg 0) (mc/cycle-forward))
   (mc/mark-previous-like-this arg)
   (rk/mc-cursors-merge)
   (when (>= arg 0) (mc/cycle-backward))))

(global-set-key (kbd "C-S-<") 'rk/mc-mark-previous-like-this-and-cycle-backward)
(global-set-key (kbd "C-c <") 'rk/mc-mark-previous-like-this-and-cycle-backward)
(global-set-key (kbd "C-S->") 'rk/mc-mark-next-like-this-and-cycle-forward)
(global-set-key (kbd "C-c >") 'rk/mc-mark-next-like-this-and-cycle-forward)
(global-set-key (kbd "C-M-n") 'mc/mark-next-lines)
(global-set-key (kbd "C-M-p") 'mc/mark-previous-lines)
(global-set-key (kbd "C-x R") 'mc/edit-lines)
'';

  home.packages = with pkgs; [
    nil # nix lsp
    nixpkgs-fmt # nix language server
    direnv
  ];    

  programs.bash = {
    enable = true;
    initExtra = ''
      if [ -f $HOME/.bashrc.backup ];
      then
        source $HOME/.bashrc.backup
      fi
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        user = "git";
        identitiesOnly = true;
        identityFile = [ "~/.ssh/id_rsa.github" ];
      };
    };
  };
}
