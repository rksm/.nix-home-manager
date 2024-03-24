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
    ];
  };

  home.file.".emacs.d/init.el".text = ''
(setq indent-tabs-mode nil
      tab-width 2
      dired-recursive-deletes 'always
      dired-recursive-copies 'always
      dired-clean-confirm-killing-deleted-buffers nil
      initial-major-mode 'fundamental-mode
      inhibit-startup-message t
      ring-bell-function 'ignore)

(setq-default case-fold-search t
              case-replace t ;; should replace keep case?
              compilation-scroll-output t
              compilation-ask-about-save nil
              truncate-lines t
              truncate-partial-width-windows nil
              make-backup-files t
              backup-directory-alist `(("." . ,(expand-file-name "backups" user-emacs-directory)))
              kept-new-versions 6
              kept-old-versions 2
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
(vertico-mode)
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles basic partial-completion))))

;; ---------------------
(setq lsp-nix-nil-formatter ["nixpkgs-fmt"])
(add-hook 'nix-mode-hook 'lsp-deferred)

;; ---------------------
(defun rk/rustic-mode-hook ()
  ;;(rustic-setup-lsp)
  (flycheck-mode)
  (setq-local lsp-inlay-hint-enable t)
  (add-hook 'before-save-hook 'lsp-format-buffer nil t)
  (setq-local buffer-save-without-query t))

(add-hook 'rustic-mode-hook 'rk/rustic-mode-hook)
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

  programs.gh = {
    enable = true;
  };
}
