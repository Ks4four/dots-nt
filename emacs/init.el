(setq custom-file (locate-user-emacs-file "custom.el"))
(load custom-file :no-error-if-file-is-missing)

;;; ============================================================
;;; PACKAGE MANAGER SETUP (straight.el)
;;; ============================================================
;;; straight.el 是基于 Git 的包管理器，比 package.el 更可靠
;;; Bootstrap 代码必须在最前面执行

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         user-emacs-directory))
      (bootstrap-version 6))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; 让 use-package 使用 straight.el 作为后端
(straight-use-package 'use-package)
(setq straight-use-package-by-default t)

;; 隐藏编译警告
(add-to-list 'display-buffer-alist
             '("\\`\\*\\(Warnings\\|Compile-Log\\)\\*\\'"
               (display-buffer-no-window)
               (allow-no-window . t)))

;;; ============================================================
;;; BASIC BEHAVIOUR
;;; ============================================================

;; delete-selection-mode
(add-hook 'after-init-hook #'delete-selection-mode)

(defun prot/keyboard-quit-dwim ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the regular `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((derived-mode-p 'completion-list-mode)
    (delete-completion-window))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

(define-key global-map (kbd "C-g") #'prot/keyboard-quit-dwim)

;;; ============================================================
;;; UI APPEARANCE
;;; ============================================================

(menu-bar-mode 1)
(scroll-bar-mode 1)
(tool-bar-mode -1)

;;; ---------- 字体配置 ----------
;;; 等宽：英文/日文 M PLUS 1 Code，中文 Sarasa Mono SC
;;; 非等宽：英文 M PLUS 2，中文 Sarasa UI SC，日文 M PLUS 1 Code

(defvar font-config--mono-en "M PLUS 1 Code")
(defvar font-config--mono-zh "Sarasa Mono SC")
(defvar font-config--mono-ja "M PLUS 1 Code")
(defvar font-config--prop-en "M PLUS 2")
(defvar font-config--prop-zh "Sarasa UI SC")
(defvar font-config--prop-ja "M PLUS 1 Code")
(defvar font-config--size 14)

(defun font-config--setup ()
  "设置字体。"
  ;; 默认字体（英文等宽）
  (set-face-attribute 'default nil
                      :family font-config--mono-en
                      :height (* font-config--size 10))
  
  ;; fixed-pitch（等宽）
  (set-face-attribute 'fixed-pitch nil
                      :family font-config--mono-en
                      :height 1.0)
  
  ;; variable-pitch（非等宽）
  (set-face-attribute 'variable-pitch nil
                      :family font-config--prop-en
                      :height 1.0)
  
  ;; 中文字体（等宽）- 用于 default 和 fixed-pitch
  (set-fontset-font t 'han (font-spec :family font-config--mono-zh))
  (set-fontset-font t 'cjk-misc (font-spec :family font-config--mono-zh))
  (set-fontset-font t 'bopomofo (font-spec :family font-config--mono-zh))
  
  ;; 日文假名（等宽）
  (set-fontset-font t 'kana (font-spec :family font-config--mono-ja))
  (set-fontset-font t 'katakana-jisx0201 (font-spec :family font-config--mono-ja))
  
  ;; 为 variable-pitch 创建专用 fontset
  (let ((fontset-name "fontset-variable"))
    (when (x-list-fonts fontset-name)
      (clear-face-attribute 'variable-pitch :fontset))
    ;; 创建基于 variable-pitch 英文字体的 fontset
    (create-fontset-from-fontset-spec
     (concat "-*-" font-config--prop-en "-*-*-*-*-*-*-*-*-*-*-" fontset-name))
    ;; 设置 variable-pitch 的中文字体
    (set-fontset-font fontset-name 'han (font-spec :family font-config--prop-zh))
    (set-fontset-font fontset-name 'cjk-misc (font-spec :family font-config--prop-zh))
    (set-fontset-font fontset-name 'bopomofo (font-spec :family font-config--prop-zh))
    ;; 日文假名（即使在 variable-pitch 也用等宽）
    (set-fontset-font fontset-name 'kana (font-spec :family font-config--prop-ja))
    (set-fontset-font fontset-name 'katakana-jisx0201 (font-spec :family font-config--prop-ja))))

;; GUI 启动时设置字体
(if (display-graphic-p)
    (font-config--setup)
  (add-hook 'server-after-make-frame-hook #'font-config--setup))

;;; ---------- 主题包安装 ----------

(straight-use-package 'modus-themes)
(straight-use-package 'ef-themes)
(straight-use-package 'doom-themes)

(load-theme 'modus-vivendi-tinted :no-confirm-loading)

(with-eval-after-load 'doom-themes
  (setq doom-themes-enable-bold t)
  (setq doom-themes-enable-italic t)
  (doom-themes-org-config))

;;; ---------- Org-mode 字体配置 ----------
;;; 特定元素使用 fixed-pitch（等宽）

(with-eval-after-load 'org
  ;; #+TITLE:, #+AUTHOR:, #+TAGS: 等关键字行
  (set-face-attribute 'org-meta-line nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-document-info-keyword nil :inherit 'fixed-pitch)
  
  ;; :PROPERTIES: 抽屉
  (set-face-attribute 'org-drawer nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-special-keyword nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-property-value nil :inherit 'fixed-pitch)
  
  ;; 标签 :tag:
  (set-face-attribute 'org-tag nil :inherit 'fixed-pitch)
  
  ;; 时间戳 [2025-11-03 17:16:20]
  (set-face-attribute 'org-date nil :inherit 'fixed-pitch)
  
  ;; 代码
  (set-face-attribute 'org-code nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-verbatim nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-block-begin-line nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-block-end-line nil :inherit 'fixed-pitch)
  
  ;; 表格
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  
  ;; 复选框
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

;;; ---------- 图标 ----------

(straight-use-package 'nerd-icons)

(straight-use-package 'nerd-icons-completion)
(with-eval-after-load 'marginalia
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(straight-use-package 'nerd-icons-corfu)
(with-eval-after-load 'corfu
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(straight-use-package 'nerd-icons-dired)
(add-hook 'dired-mode-hook #'nerd-icons-dired-mode)

;;; ============================================================
;;; MINIBUFFER AND COMPLETIONS
;;; ============================================================

(straight-use-package 'vertico)
(add-hook 'after-init-hook #'vertico-mode)

(straight-use-package 'marginalia)
(add-hook 'after-init-hook #'marginalia-mode)

(straight-use-package 'orderless)
(with-eval-after-load 'orderless
  (setq completion-styles '(orderless basic))
  (setq completion-category-defaults nil)
  (setq completion-category-overrides nil))

;; savehist (内置)
(add-hook 'after-init-hook #'savehist-mode)

(straight-use-package 'corfu)
(add-hook 'after-init-hook #'global-corfu-mode)
(with-eval-after-load 'corfu
  (define-key corfu-map (kbd "<tab>") #'corfu-complete)
  (setq tab-always-indent 'complete)
  (setq corfu-preview-current nil)
  (setq corfu-min-width 20)
  (setq corfu-popupinfo-delay '(1.25 . 0.5))
  (corfu-popupinfo-mode 1)
  (with-eval-after-load 'savehist
    (corfu-history-mode 1)
    (add-to-list 'savehist-additional-variables 'corfu-history)))

;;; ============================================================
;;; FILE MANAGER (DIRED)
;;; ============================================================

;; dired (内置)
(with-eval-after-load 'dired
  (setq dired-recursive-copies 'always)
  (setq dired-recursive-deletes 'always)
  (setq delete-by-moving-to-trash t)
  (setq dired-dwim-target t))

(add-hook 'dired-mode-hook #'dired-hide-details-mode)
(add-hook 'dired-mode-hook #'hl-line-mode)

(straight-use-package 'dired-subtree)
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "<tab>") #'dired-subtree-toggle)
  (define-key dired-mode-map (kbd "TAB") #'dired-subtree-toggle)
  (define-key dired-mode-map (kbd "<backtab>") #'dired-subtree-remove)
  (define-key dired-mode-map (kbd "S-TAB") #'dired-subtree-remove))
(with-eval-after-load 'dired-subtree
  (setq dired-subtree-use-backgrounds nil))

(straight-use-package 'trashed)
(with-eval-after-load 'trashed
  (setq trashed-action-confirmer 'y-or-n-p)
  (setq trashed-use-header-line t)
  (setq trashed-sort-key '("Date deleted" . t))
  (setq trashed-date-format "%Y-%m-%d %H:%M:%S"))

;;; ============================================================
;;; ARTIST DATABASE MANAGEMENT
;;; ============================================================
;;; 画师数据库管理系统，使用 Org-mode 存储数据，支持 Danbooru API 导入。
;;;
;;; 入口命令（可直接 M-x 调用，会自动加载 org）：
;;;   artist-new             - 通过 capture 创建新画师
;;;   artist-search          - 搜索画师
;;;   artist-danbooru-search - 从 Danbooru 导入
;;;   artist-open-database   - 打开数据库文件
;;;   artist-setup-danbooru  - 设置 API 凭证
;;;
;;; 代码结构：
;;;   1. 配置变量（启动时求值，开销小）
;;;   2. 预计算常量（启动时计算一次）
;;;   3. 独立命令（不依赖 org）
;;;   4. 入口桩函数（按需加载 org）
;;;   5. 核心实现（with-eval-after-load 'org 懒加载）
;;; ============================================================

;;; ---------- 配置变量 ----------

(defgroup artist-db nil
  "画师数据库配置"
  :group 'org)

(defcustom artist-db-file
  (if (memq system-type '(windows-nt ms-dos cygwin))
      "D:/org/moe/artist.org"
    "~/org/moe/artist.org")
  "主画师数据库文件"
  :type 'file
  :group 'artist-db)

(defcustom artist-db-attach-dir
  (if (memq system-type '(windows-nt ms-dos cygwin))
      "D:/org/moe/data/"
    "~/org/moe/data/")
  "画师图片附件目录"
  :type 'directory
  :group 'artist-db)

(defcustom artist-db-default-region "japan"
  "默认地区"
  :type 'string
  :group 'artist-db)

(defcustom artist-db-tag-presets
  '("general/loli"
    "general/solo"
    "general/feet"
    "copyright/blue_archive"
    "copyright/touhou"
    "backgrounds"
    "subjective/pricing/overpriced"
    "subjective/pricing/underpriced")
  "预设标签列表"
  :type '(repeat string)
  :group 'artist-db)

(defgroup artist-db-danbooru nil
  "Danbooru API设置"
  :group 'artist-db)

(defcustom artist-db-danbooru-user ""
  "Danbooru用户名"
  :type 'string
  :group 'artist-db-danbooru)

(defcustom artist-db-danbooru-api-key ""
  "Danbooru API密钥"
  :type 'string
  :group 'artist-db-danbooru)

(defcustom artist-db-danbooru-debug nil
  "是否开启调试输出"
  :type 'boolean
  :group 'artist-db-danbooru)

;;; ---------- 预计算常量 ----------

(defconst artist-db--index-file-regexp "artist.*index\\.org"
  "匹配画师索引文件的正则")

(defconst artist-db--heading-regexp "^\\* \\([^[:space:]]+\\)$"
  "匹配一级标题的正则")

(defconst artist-db--heading-with-content-regexp "^\\* \\(.+\\)$"
  "匹配一级标题（含空格）的正则")

(defvar artist-db--is-wsl
  (and (eq system-type 'gnu/linux)
       (string-match-p "microsoft\\|wsl"
                       (downcase (shell-command-to-string "uname -r"))))
  "是否运行在 WSL 环境")

(defvar artist-db--is-windows
  (memq system-type '(windows-nt ms-dos cygwin))
  "是否运行在 Windows 环境")

(defvar artist-db--curl-available (executable-find "curl")
  "curl 是否可用")

(defvar artist-db--wget-available (executable-find "wget")
  "wget 是否可用")

;;; ---------- 独立命令 ----------

(defun artist-setup-danbooru ()
  "设置Danbooru API认证"
  (interactive)
  (setq artist-db-danbooru-user
        (read-string "Danbooru用户名: " artist-db-danbooru-user))
  (setq artist-db-danbooru-api-key
        (read-string "Danbooru API密钥: " artist-db-danbooru-api-key))
  (customize-save-variable 'artist-db-danbooru-user artist-db-danbooru-user)
  (customize-save-variable 'artist-db-danbooru-api-key artist-db-danbooru-api-key)
  (message "Danbooru认证已保存"))

(defun artist-toggle-debug ()
  "切换调试模式"
  (interactive)
  (setq artist-db-danbooru-debug (not artist-db-danbooru-debug))
  (message "Artist DB调试模式: %s" (if artist-db-danbooru-debug "开启" "关闭")))

(defun artist-open-database ()
  "打开画师数据库"
  (interactive)
  (find-file artist-db-file))

;;; ---------- 入口桩函数 ----------

(defun artist-new ()
  "创建新画师条目"
  (interactive)
  (require 'org)
  (call-interactively #'artist-new))

(defun artist-update-price ()
  "更新画师价格"
  (interactive)
  (require 'org)
  (call-interactively #'artist-update-price))

(defun artist-search ()
  "搜索画师"
  (interactive)
  (require 'org)
  (call-interactively #'artist-search))

(defun artist-search-by-tag ()
  "按标签搜索"
  (interactive)
  (require 'org)
  (call-interactively #'artist-search-by-tag))

(defun artist-search-by-property ()
  "按属性搜索"
  (interactive)
  (require 'org)
  (call-interactively #'artist-search-by-property))

(defun artist-paste-table ()
  "粘贴为Org表格"
  (interactive)
  (require 'org)
  (call-interactively #'artist-paste-table))

(defun artist-attach-image ()
  "附加图片到当前画师"
  (interactive)
  (require 'org)
  (call-interactively #'artist-attach-image))

(defun artist-import-from-url ()
  "从URL导入画师"
  (interactive)
  (require 'org)
  (call-interactively #'artist-import-from-url))

(defun artist-danbooru-search ()
  "搜索Danbooru画师"
  (interactive)
  (require 'org)
  (call-interactively #'artist-danbooru-search))

(defun artist-test-danbooru ()
  "测试Danbooru连接"
  (interactive)
  (require 'org)
  (call-interactively #'artist-test-danbooru))

(defun artist-add-log ()
  "快速添加Log条目"
  (interactive)
  (require 'org)
  (call-interactively #'artist-add-log))

(defun artist-insert-id-link ()
  "快速插入画师ID链接"
  (interactive)
  (require 'org)
  (call-interactively #'artist-insert-id-link))

;;; ---------- 核心实现 ----------

(with-eval-after-load 'org
  (require 'org-capture)
  (require 'json)
  (require 'url-util)  ; 确保 url-hexify-string 可用

  ;;; Buffer-local 变量
  (defvar-local artist-db--is-index-file nil
    "当前buffer是否为画师索引文件")

  (defvar-local artist-db-last-heading nil
    "记录上一次光标所在的一级标题位置")

  ;;; 调试宏
  (defmacro artist-db-debug (fmt &rest args)
    `(when artist-db-danbooru-debug
       (message ,(concat "[Artist-DB] " fmt) ,@args)))

  ;;; ---- 内部工具函数 ----

  (defun artist-db-get-current-main-heading ()
    "获取当前光标所在的一级标题位置"
    (save-excursion
      (condition-case nil
          (progn
            (org-back-to-heading t)
            (while (> (org-outline-level) 1)
              (org-up-heading-safe))
            (point))
        (error nil))))

  (defun artist-db--find-file-setup ()
    "find-file-hook 回调"
    (let ((fn (buffer-file-name)))
      (when (and fn (string-match-p artist-db--index-file-regexp fn))
        (setq artist-db--is-index-file t)
        (setq artist-db-last-heading (artist-db-get-current-main-heading))
        (add-hook 'post-command-hook
                  #'artist-db-update-modified-on-heading-change nil t))))

  (defun artist-db-update-modified-on-heading-change ()
    "当离开一个主树时更新其 MODIFIED 属性"
    (when artist-db--is-index-file
      (let ((current-heading (artist-db-get-current-main-heading)))
        (when (and artist-db-last-heading
                   (not (equal artist-db-last-heading current-heading)))
          (save-excursion
            (goto-char artist-db-last-heading)
            (when (org-entry-get nil "CREATED")
              (org-entry-put nil "MODIFIED"
                             (format-time-string "[%Y-%m-%d %H:%M:%S]")))))
        (setq artist-db-last-heading current-heading))))

  (defun artist-db-set-created-property ()
    "设置CREATED属性（如果不存在）"
    (save-excursion
      (org-back-to-heading t)
      (unless (org-entry-get nil "CREATED")
        (org-entry-put nil "CREATED"
                       (format-time-string "[%Y-%m-%d %H:%M:%S]")))))

  ;;; ---- 表格转换函数 ----

  (defun artist-db-tsv-to-org-table (text)
    "将制表符分隔的文本转换为Org表格"
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (search-forward "\t" nil t)
        (replace-match " | "))
      (goto-char (point-min))
      (while (not (eobp))
        (beginning-of-line)
        (insert "| ")
        (end-of-line)
        (insert " |")
        (forward-line))
      (goto-char (point-min))
      (org-table-align)
      (buffer-string)))

  (defun artist-db-csv-to-org-table (text)
    "将CSV格式转换为Org表格"
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "\"\\([^\"]*\\)\"" nil t)
        (let ((content (match-string 1)))
          (replace-match (replace-regexp-in-string "," "，" content))))
      (goto-char (point-min))
      (while (search-forward "," nil t)
        (replace-match " | "))
      (goto-char (point-min))
      (while (not (eobp))
        (beginning-of-line)
        (insert "| ")
        (end-of-line)
        (insert " |")
        (forward-line))
      (goto-char (point-min))
      (org-table-align)
      (buffer-string)))

  (defun artist-db-space-to-org-table (text)
    "将多空格分隔的文本转换为Org表格"
    (with-temp-buffer
      (insert text)
      (goto-char (point-min))
      (while (re-search-forward "\\s-\\{2,\\}" nil t)
        (replace-match " | "))
      (goto-char (point-min))
      (while (not (eobp))
        (beginning-of-line)
        (insert "| ")
        (end-of-line)
        (insert " |")
        (forward-line))
      (goto-char (point-min))
      (org-table-align)
      (buffer-string)))

  ;;; ---- Danbooru API ----

  (defun artist-db-danbooru-request (endpoint &optional params)
    "请求Danbooru API，返回解析后的JSON"
    (when (or (string-empty-p artist-db-danbooru-user)
              (string-empty-p artist-db-danbooru-api-key))
      (user-error "请先设置Danbooru认证信息 (M-x artist-setup-danbooru)"))
    (let* ((base-url "https://danbooru.donmai.us")
           (full-url (if params
                         (concat base-url endpoint "?" params)
                       (concat base-url endpoint)))
           (cmd nil)
           (output nil))
      (artist-db-debug "请求URL: %s" full-url)
      (cond
       (artist-db--curl-available
        (if artist-db--is-windows
            (setq cmd (format "curl -s -L -u \"%s:%s\" \"%s\""
                              artist-db-danbooru-user
                              artist-db-danbooru-api-key
                              full-url))
          (setq cmd (format "curl -s -L -u '%s:%s' '%s'"
                            artist-db-danbooru-user
                            artist-db-danbooru-api-key
                            full-url))))
       (artist-db--wget-available
        (if artist-db--is-windows
            (setq cmd (format "wget -q -O - --user=\"%s\" --password=\"%s\" \"%s\""
                              artist-db-danbooru-user
                              artist-db-danbooru-api-key
                              full-url))
          (setq cmd (format "wget -q -O - --user='%s' --password='%s' '%s'"
                            artist-db-danbooru-user
                            artist-db-danbooru-api-key
                            full-url))))
       (t
        (user-error "需要安装curl或wget")))
      (artist-db-debug "执行命令: %s" cmd)
      (setq output (shell-command-to-string cmd))
      (artist-db-debug "响应长度: %d" (length output))
      (when artist-db-danbooru-debug
        (if (> (length output) 200)
            (artist-db-debug "响应前200字符: %s" (substring output 0 200))
          (artist-db-debug "响应内容: %s" output)))
      (if (and output (not (string-empty-p output)))
          (condition-case err
              (let ((json-object-type 'alist)
                    (json-array-type 'list)
                    (json-key-type 'string)
                    (json-false nil))
                (json-read-from-string output))
            (error
             (artist-db-debug "JSON解析错误: %s" err)
             nil))
        (artist-db-debug "响应为空")
        nil)))

  (defun artist-db-danbooru-search-artists (query)
    "搜索画师"
    (let* ((is-url (string-match-p "^https?://" query))
           (encoded-query (url-hexify-string query))
           (search-param nil))
      (if is-url
          (setq search-param
                (concat "search" "%5B" "url_matches" "%5D" "=" encoded-query))
        (setq search-param
              (concat "search" "%5B" "any_name_or_url_matches" "%5D" "=" encoded-query)))
      (artist-db-debug "搜索类型: %s, 查询: %s" (if is-url "URL" "名称") query)
      (artist-db-debug "搜索参数: %s" search-param)
      (artist-db-danbooru-request "/artists.json"
                                  (concat "limit=20&" search-param))))

  (defun artist-db-danbooru-get-artist (id)
    "获取画师详情"
    (artist-db-danbooru-request
     (format "/artists/%s.json" id)
     "only=id,name,group_name,is_banned,is_deleted,other_names,wiki_page"))

  (defun artist-db-danbooru-get-artist-urls (id)
    "获取画师URLs"
    (let ((param (concat "search" "%5B" "artist_id" "%5D" "="
                         (if (numberp id) (number-to-string id) id)
                         "&limit=100")))
      (artist-db-danbooru-request "/artist_urls.json" param)))

  ;;; ---- 数据库操作 ----

  (defun artist-db-get-all-artists ()
    "获取所有画师名称列表"
    (with-current-buffer (find-file-noselect artist-db-file)
      (save-excursion
        (goto-char (point-min))
        (let (artists)
          (while (re-search-forward artist-db--heading-regexp nil t)
            (push (match-string 1) artists))
          (nreverse artists)))))

  (defun artist-db-goto-price-section ()
    "跳转到价格更新位置"
    (find-file artist-db-file)
    (let ((artist (completing-read "选择画师: "
                                   (artist-db-get-all-artists))))
      (goto-char (point-min))
      (re-search-forward (format "^\\* %s$" (regexp-quote artist)) nil t)
      (let ((section (completing-read "更新哪个平台价格? "
                                      '("Skeb" "Pixiv Request")
                                      nil t)))
        (if (re-search-forward (format "^\\*\\* %s$" section) nil t)
            (org-end-of-subtree)
          (user-error "未找到%s部分" section)))))

  ;;; ---- 从 Danbooru 导入 ----

  (defun artist-db-import-from-danbooru (query)
    "从 Danbooru 导入画师信息"
    (interactive "s输入URL或画师名: ")
    (when (or (string-empty-p artist-db-danbooru-user)
              (string-empty-p artist-db-danbooru-api-key))
      (call-interactively #'artist-setup-danbooru))
    (message "搜索Danbooru: %s" query)
    (condition-case err
        (let ((artists (artist-db-danbooru-search-artists query)))
          (unless (and artists (listp artists) (> (length artists) 0))
            (user-error "未找到匹配的画师"))
          (message "找到 %d 个画师" (length artists))
          ;; 选择画师
          (let* ((chosen (if (= (length artists) 1)
                             (car artists)
                           (let ((choices nil))
                             (let ((tmp artists))
                               (while tmp
                                 (let* ((a (car tmp))
                                        (aname (cdr (assoc "name" a)))
                                        (aid (cdr (assoc "id" a))))
                                   (push (cons (format "%s (id:%s)" (or aname "?") (or aid "?")) a)
                                         choices))
                                 (setq tmp (cdr tmp))))
                             (setq choices (nreverse choices))
                             (cdr (assoc (completing-read "选择画师: "
                                                          (mapcar #'car choices)
                                                          nil t)
                                         choices)))))
                 (chosen-id (cdr (assoc "id" chosen)))
                 (chosen-name (cdr (assoc "name" chosen))))
            (unless (and chosen-id chosen-name)
              (user-error "无法获取画师信息"))
            (message "获取详情: %s (ID: %s)" chosen-name chosen-id)
            ;; 获取详情和URLs
            (let ((detail (artist-db-danbooru-get-artist chosen-id))
                  (urls (artist-db-danbooru-get-artist-urls chosen-id)))
              ;; 一次遍历 detail 提取所有需要的字段
              (let ((other-names nil)
                    (group-name "")
                    (wiki-body ""))
                (let ((d detail))
                  (while d
                    (let ((k (caar d))
                          (v (cdar d)))
                      (cond
                       ((string= k "other_names") (setq other-names v))
                       ((string= k "group_name")
                        (when (and v (stringp v) (not (string-empty-p v)))
                          (setq group-name v)))
                       ((string= k "wiki_page")
                        (when (listp v)
                          (let ((body (cdr (assoc "body" v))))
                            (when (and body (stringp body) (not (string-empty-p body)))
                              (setq wiki-body body)))))))
                    (setq d (cdr d))))
                ;; 调用创建函数
                (artist-db-create-entry-from-danbooru
                 chosen-name chosen-id group-name other-names urls wiki-body)))))
      (error
       (message "导入失败: %s" (error-message-string err))
       (user-error "导入失败: %s" (error-message-string err)))))

  (defun artist-db-create-entry-from-danbooru (name id group-name aliases urls wiki)
    "创建画师条目"
    (find-file artist-db-file)
    (goto-char (point-max))
    ;; 检查是否已存在
    (save-excursion
      (goto-char (point-min))
      (when (re-search-forward (format "^\\* %s$" (regexp-quote name)) nil t)
        (unless (y-or-n-p (format "画师 %s 已存在，是否覆盖？" name))
          (user-error "取消创建"))))
    ;; 预计算时间戳
    (let* ((now (current-time))
           (ts-id (format-time-string "%Y-%m-%dT%H.%M.%S" now))
           (ts-display (format-time-string "[%Y-%m-%d %H:%M:%S]" now))
           (artist-id (concat "ARTIST-" ts-id))
           (skeb-id (concat "SKEB-" ts-id))
           (pixiv-id (concat "PIXIV-" ts-id))
           ;; 格式化别名
           (aliases-str (if (and aliases (listp aliases))
                            (mapconcat 'identity aliases " ")
                          ""))
           ;; 一次遍历 urls 提取所有信息
           (has-skeb nil)
           (has-pixiv nil)
           (active-urls nil)
           (inactive-urls nil))
      ;; 遍历 URLs
      (let ((tmp urls))
        (while tmp
          (let* ((u (car tmp))
                 (url (cdr (assoc "url" u)))
                 (active (cdr (assoc "is_active" u))))
            (when url
              (when (string-match-p "skeb\\.jp" url) (setq has-skeb t))
              (when (string-match-p "pixiv\\.net" url) (setq has-pixiv t))
              (if active
                  (push (format "- <%s>" url) active-urls)
                (push (format "- +<%s>+" url) inactive-urls))))
          (setq tmp (cdr tmp))))
      ;; 构建 URL 列表字符串
      (let ((url-list ""))
        (let ((tmp (nreverse active-urls)))
          (while tmp
            (setq url-list (concat url-list (car tmp) "\n"))
            (setq tmp (cdr tmp))))
        (let ((tmp (nreverse inactive-urls)))
          (while tmp
            (setq url-list (concat url-list (car tmp) "\n"))
            (setq tmp (cdr tmp))))
        ;; 交互获取信息
        (let* ((is-nsfw (y-or-n-p "是否NSFW画师? "))
               (skeb-request (if has-skeb
                                 (completing-read "Skeb开放委托? "
                                                  '("t" "nil" "unknown" "na") nil t)
                               "na"))
               (skeb-nsfw-ok (if (and has-skeb (equal skeb-request "t") is-nsfw)
                                 (completing-read "Skeb接受NSFW委托? "
                                                  '("t" "nil" "unknown") nil t)
                               (if (or (equal skeb-request "nil") (equal skeb-request "na"))
                                   "na" "nil")))
               (pixiv-request (if has-pixiv
                                  (completing-read "Pixiv开放委托? "
                                                   '("t" "nil" "unknown" "na") nil t)
                                "na"))
               (pixiv-r18-ok (if (and has-pixiv (equal pixiv-request "t") is-nsfw)
                                 (completing-read "Pixiv接受R18委托? "
                                                  '("t" "nil" "unknown") nil t)
                               (if (or (equal pixiv-request "nil") (equal pixiv-request "na"))
                                   "na" "nil")))
               (region (completing-read "地区: "
                                        '("japan" "china" "korea" "western" "taiwan" "hongkong" "unknown")
                                        nil nil nil nil "japan"))
               ;; 格式化 wiki
               (wiki-formatted (if (and wiki (not (string-empty-p wiki)))
                                   (concat "#+begin_example\n"
                                           (with-temp-buffer
                                             (insert wiki)
                                             (goto-char (point-min))
                                             (while (re-search-forward "^\\([*]\\|#\\+\\|,\\*\\|,#\\+\\)" nil t)
                                               (goto-char (match-beginning 0))
                                               (insert ",")
                                               (forward-line))
                                             (buffer-string))
                                           "\n#+end_example")
                                 "")))
          ;; 插入条目
          (insert (format "
* %s
:PROPERTIES:
:ID: %s
:DANBOORU_NAME: %s
:DANBOORU_URL: <https://danbooru.donmai.us/artists/%s>
:ALIASES: %s
:GROUP_NAME: %s
:NSFW: %s
:EMAIL_ADDRESS: 
:REGION: %s
:CREATED: %s
:MODIFIED: %s
:END:

** Log
- %s :: 从 Danbooru 导入。

** URLs
%s
** Wiki
%s

** Skeb
:PROPERTIES:
:SKEB_REQUEST: %s
:SKEB_NSFW_OK: %s
:END:

*** %s
:PROPERTIES:
:ID: %s
:END:

** Pixiv Request
:PROPERTIES:
:PIXIV_REQUEST: %s
:PIXIV_R18_OK: %s
:END:

*** %s
:PROPERTIES:
:ID: %s
:PIXIV_PRICE:
:END:

** Sample Images

"
                          name artist-id name id aliases-str group-name
                          (if is-nsfw "t" "nil")
                          region
                          ts-display ts-display ts-display
                          url-list wiki-formatted
                          skeb-request skeb-nsfw-ok ts-display skeb-id
                          pixiv-request pixiv-r18-ok ts-display pixiv-id)))))
    (save-buffer)
    (message "✓ 已创建画师条目: %s" name)
    (goto-char (point-max))
    (re-search-backward (format "^\\* %s$" (regexp-quote name)) nil t))

  ;;; ---- 交互命令 ----

  (defun artist-new ()
    "创建新画师条目"
    (interactive)
    (org-capture nil "a"))

  (defun artist-update-price ()
    "更新画师价格"
    (interactive)
    (org-capture nil "u"))

  (defun artist-paste-table ()
    "粘贴为Org表格"
    (interactive)
    (let* ((clipboard-text
            (if artist-db--is-wsl
                (let ((text (shell-command-to-string "powershell.exe -Command Get-Clipboard")))
                  (with-temp-buffer
                    (insert text)
                    (goto-char (point-min))
                    (while (search-forward "\r" nil t)
                      (replace-match ""))
                    (string-trim (buffer-string))))
              (gui-get-selection 'CLIPBOARD 'UTF8_STRING))))
      (cond
       ((null clipboard-text)
        (user-error "剪贴板为空"))
       ((string-match-p "\t" clipboard-text)
        (message "检测到制表符分隔的表格")
        (insert (artist-db-tsv-to-org-table clipboard-text)))
       ((and (string-match-p "^[^,]+,[^,]+" clipboard-text)
             (y-or-n-p "检测到逗号分隔，是否作为CSV表格处理？"))
        (insert (artist-db-csv-to-org-table clipboard-text)))
       ((string-match-p "^|.*|$" clipboard-text)
        (insert clipboard-text)
        (org-table-align))
       ((string-match-p "\\s-\\{2,\\}" clipboard-text)
        (message "检测到多空格分隔")
        (insert (artist-db-space-to-org-table clipboard-text)))
       (t
        (insert clipboard-text)))))

  (defun artist-search ()
    "搜索画师"
    (interactive)
    (find-file artist-db-file)
    (if (fboundp 'consult-org-heading)
        (consult-org-heading)
      (call-interactively 'org-goto)))

  (defun artist-search-by-tag ()
    "按标签搜索"
    (interactive)
    (if (require 'org-ql nil t)
        (let ((tag (completing-read "标签: " artist-db-tag-presets)))
          (org-ql-search artist-db-file
            `(tags ,tag)
            :title (format "标签: %s" tag)))
      (user-error "需要安装org-ql包")))

  (defun artist-search-by-property ()
    "按属性搜索"
    (interactive)
    (if (require 'org-ql nil t)
        (let* ((props '(("NSFW" . "是否NSFW")
                        ("SKEB_REQUEST" . "Skeb开放")
                        ("PIXIV_REQUEST" . "Pixiv开放")
                        ("REGION" . "地区")
                        ("EMAIL_REQUEST" . "接受邮件委托")))
               (prop (completing-read "属性: " props))
               (value (read-string (format "%s = " (cdr (assoc prop props))))))
          (org-ql-search artist-db-file
            `(property ,prop ,value)
            :title (format "%s = %s" prop value)))
      (user-error "需要安装org-ql包")))

  (defun artist-attach-image ()
    "附加图片到当前画师"
    (interactive)
    (unless (derived-mode-p 'org-mode)
      (user-error "需要在org-mode中使用"))
    (let* ((file (read-file-name "选择图片: "))
           (filename (file-name-nondirectory file))
           (dest (expand-file-name filename artist-db-attach-dir)))
      (copy-file file dest t)
      (message "已附加图片: %s" filename)))

  (defun artist-import-from-url ()
    "从URL导入画师"
    (interactive)
    (let ((url (read-string "输入URL或画师名: ")))
      (artist-db-import-from-danbooru url)))

  (defun artist-danbooru-search ()
    "搜索Danbooru画师"
    (interactive)
    (let ((query (read-string "搜索Danbooru (名称/别名/URL): ")))
      (artist-db-import-from-danbooru query)))

  (defun artist-test-danbooru ()
    "测试Danbooru连接"
    (interactive)
    (if (and artist-db-danbooru-user artist-db-danbooru-api-key
             (not (string-empty-p artist-db-danbooru-user))
             (not (string-empty-p artist-db-danbooru-api-key)))
        (condition-case err
            (let ((result (artist-db-danbooru-request "/profile.json")))
              (if result
                  (message "✓ Danbooru连接成功! 用户: %s, 等级: %s"
                           (cdr (assoc "name" result))
                           (cdr (assoc "level_string" result)))
                (message "✗ 无响应或解析失败")))
          (error (message "✗ 连接失败: %s" (error-message-string err))))
      (message "请先设置Danbooru认证 (使用 artist-setup-danbooru)")))

  (defun artist-add-log ()
    "快速添加Log条目"
    (interactive)
    (unless (derived-mode-p 'org-mode)
      (user-error "需要在org-mode中使用"))
    (let ((main-tree-start nil)
          (main-tree-end nil))
      (save-excursion
        (org-back-to-heading t)
        (while (and (> (org-outline-level) 1)
                    (org-up-heading-safe)))
        (setq main-tree-start (point))
        (org-end-of-subtree t t)
        (setq main-tree-end (point)))
      (goto-char main-tree-start)
      (if (re-search-forward "^\\*\\* Log$" main-tree-end t)
          (progn
            (forward-line 1)
            (beginning-of-line)
            (insert (format "- [%s] :: "
                            (format-time-string "%Y-%m-%d %H:%M:%S")))
            (let ((insert-point (point)))
              (insert "\n")
              (goto-char insert-point))
            (when (and (featurep 'meow)
                       (bound-and-true-p meow-mode))
              (meow-insert)))
        (user-error "未找到Log部分"))))

  (defun artist-insert-id-link ()
    "快速插入画师ID链接"
    (interactive)
    (let ((entries nil))
      (with-current-buffer (find-file-noselect artist-db-file)
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward artist-db--heading-with-content-regexp nil t)
            (let ((name (match-string 1))
                  (id (org-entry-get nil "ID")))
              (when id
                (push (cons name id) entries))))))
      (setq entries (nreverse entries))
      (let* ((chosen (completing-read "选择画师: " entries nil t))
             (id (cdr (assoc chosen entries))))
        (insert (format "[[id:%s][%s]]" id chosen)))))

  ;;; ---- Capture 模板 ----

  (defvar artist-db-capture-template
    "* %^{画师名称}
:PROPERTIES:
:ID: %(concat \"ARTIST-\" (format-time-string \"%Y-%m-%dT%H.%M.%S\"))
:DANBOORU_NAME: %\\1
:DANBOORU_URL: <%^{Danbooru URL|https://danbooru.donmai.us/artists/}>
:ALIASES: %^{别名(空格分隔)|}
:GROUP_NAME: %^{团体名|}
:NSFW: %^{是否NSFW?|nil|t}
:EMAIL_ADDRESS: %^{Email地址|}
:REGION: %^{地区|japan|china|korea|western|hongkong|taiwan|unknown}
:CREATED: [%<%Y-%m-%d %H:%M:%S>]
:MODIFIED: [%<%Y-%m-%d %H:%M:%S>]
:END:

** Log
- %U :: %^{初始备注}

** URLs
%^{URLs (一行一个，用-开头)}

** Wiki
%^{Wiki内容|}

** Skeb
:PROPERTIES:
:SKEB_REQUEST: %^{Skeb开放委托?|nil|t|unknown|na}
:SKEB_NSFW_OK: %^{Skeb接受NSFW?|nil|t}
:END:

*** [%<%Y-%m-%d %H:%M:%S>]
:PROPERTIES:
:ID: %(concat \"SKEB-\" (format-time-string \"%Y-%m-%dT%H.%M.%S\"))
:END:
%?

** Pixiv Request
:PROPERTIES:
:PIXIV_REQUEST: %^{Pixiv开放委托?|nil|t|unknown|na}
:PIXIV_R18_OK: %^{Pixiv接受R18?|nil|t}
:END:

*** [%<%Y-%m-%d %H:%M:%S>]
:PROPERTIES:
:ID: %(concat \"PIXIV-\" (format-time-string \"%Y-%m-%dT%H.%M.%S\"))
:PIXIV_PRICE:
:END:

** Sample Images
")

  (defvar artist-db-price-update-template
    "*** [%<%Y-%m-%d %H:%M:%S>]
:PROPERTIES:
:ID: %(concat (if (string-match-p \"Skeb\" (save-excursion (org-back-to-heading) (org-get-heading))) \"SKEB-\" \"PIXIV-\") (format-time-string \"%Y-%m-%dT%H.%M.%S\"))
:PIXIV_PRICE:
:END:
%?")

  ;;; ---- Capture 模板设置 ----

  (with-eval-after-load 'org-capture
    (setq org-capture-templates
          (let ((result nil)
                (tmp org-capture-templates))
            (while tmp
              (unless (member (caar tmp) '("a" "u"))
                (push (car tmp) result))
              (setq tmp (cdr tmp)))
            (nreverse result)))
    (add-to-list 'org-capture-templates
                 `("a" "Artist Entry" entry
                   (file ,artist-db-file)
                   ,artist-db-capture-template
                   :empty-lines 1
                   :unnarrowed t))
    (add-to-list 'org-capture-templates
                 `("u" "Update Price" item
                   (function artist-db-goto-price-section)
                   ,artist-db-price-update-template
                   :empty-lines 1)))

  ;;; ---- Hooks ----

  (add-hook 'find-file-hook #'artist-db--find-file-setup)
  (add-hook 'org-capture-before-finalize-hook #'artist-db-set-created-property)

  ;;; ---- 目录初始化 ----

  (unless (file-exists-p (file-name-directory artist-db-file))
    (make-directory (file-name-directory artist-db-file) t))
  (unless (file-exists-p artist-db-attach-dir)
    (make-directory artist-db-attach-dir t))

  ) ;; End of with-eval-after-load 'org

;;; ============================================================
;;; COFFEE TASTING LOG MANAGEMENT
;;; ============================================================
;;; 咖啡品鉴日志管理系统
;;;
;;; 入口命令：
;;;   coffee-open-log       - 打开日志文件
;;;   coffee-new-bean       - 添加新咖啡豆
;;;   coffee-new-batch      - 添加新烘焙批次
;;;   coffee-new-brew       - 添加冲煮记录
;;;   coffee-new-cafe       - 添加咖啡店记录
;;;   coffee-export-to-html - 导出HTML
;;;   coffee-insert-image   - 插入图片附件
;;;   coffee-menu           - Transient菜单（需安装transient）
;;; ============================================================

;;; ---------- 配置变量 ----------

(defgroup coffee-log nil
  "Coffee tasting log configuration."
  :group 'org)

(defcustom coffee-project-dir
  (if (memq system-type '(windows-nt ms-dos cygwin))
      "D:/org/coffee/"
    "~/org/coffee/")
  "Root directory of the coffee project."
  :type 'directory
  :group 'coffee-log)

(defcustom coffee-log-file
  (if (memq system-type '(windows-nt ms-dos cygwin))
      "D:/org/coffee/index.org"
    "~/org/coffee/index.org")
  "Path to the coffee tasting log file."
  :type 'file
  :group 'coffee-log)

(defcustom coffee-attach-dir
  (if (memq system-type '(windows-nt ms-dos cygwin))
      "D:/org/coffee/data/"
    "~/org/coffee/data/")
  "Directory for storing all org-attach attachments."
  :type 'directory
  :group 'coffee-log)

(defconst coffee--capture-key "c"
  "Prefix for coffee capture template keybindings.")

;;; ---------- 独立命令 ----------

(defun coffee-open-log ()
  "Open the coffee tasting log file."
  (interactive)
  (find-file coffee-log-file))

;;; ---------- 入口桩函数 ----------

(defun coffee-new-bean ()
  "Capture a new coffee bean."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-new-bean))

(defun coffee-new-batch ()
  "Capture a new roasted batch."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-new-batch))

(defun coffee-new-brew ()
  "Capture a detailed brew record."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-new-brew))

(defun coffee-new-cafe ()
  "Capture a cafe drink record."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-new-cafe))

(defun coffee-export-to-html ()
  "Export coffee tastings to HTML."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-export-to-html))

(defun coffee-insert-image ()
  "Insert image attachment."
  (interactive)
  (require 'org)
  (call-interactively #'coffee-insert-image))

;;; ---------- 核心实现 ----------

(with-eval-after-load 'org
  (require 'org-capture)
  (require 'org-attach)
  (require 'org-id)

  ;;; ---- 内部函数 ----

  (defun coffee--select-bean ()
    "Select a coffee bean (Level 1) for adding a batch."
    (goto-char (point-min))
    (let* ((beans (org-map-entries
                   (lambda ()
                     (cons (org-entry-get nil "NAME")
                           (point)))
                   "+LEVEL=1"
                   'file))
           (bean (completing-read "Select coffee bean: "
                                  (mapcar #'car beans) nil t)))
      (goto-char (cdr (assoc bean beans)))))

  (defun coffee--select-bean-then-batch ()
    "First select a bean, then select a batch under that bean."
    (goto-char (point-min))
    (let* ((beans (org-map-entries
                   (lambda ()
                     (cons (org-entry-get nil "NAME")
                           (point)))
                   "+LEVEL=1"
                   'file))
           (bean (completing-read "Select coffee bean: "
                                  (mapcar #'car beans) nil t))
           (bean-point (cdr (assoc bean beans))))
      (goto-char bean-point)
      (let ((batches nil))
        (save-excursion
          (org-narrow-to-subtree)
          (org-map-entries
           (lambda ()
             (let ((roaster (org-entry-get nil "ROASTER"))
                   (roast-date (org-entry-get nil "ROAST_DATE"))
                   (profile (org-entry-get nil "ROAST_PROFILE")))
               (push (cons (format "%s %s (%s)"
                                   roaster
                                   (or profile "")
                                   (or roast-date ""))
                           (point))
                     batches)))
           "+LEVEL=2"
           nil)
          (widen))
        (if batches
            (let ((selected (completing-read (format "Select batch under %s: " bean)
                                             (mapcar #'car (reverse batches)) nil t)))
              (goto-char (cdr (assoc selected batches))))
          (goto-char bean-point)
          (message "No batches found under %s, creating at bean level" bean)))))

  ;;; ---- 交互命令（覆盖桩函数） ----

  (defun coffee-insert-image ()
    "Prompt the user to select an image, attach it, and insert inline link."
    (interactive)
    (let ((selected-item (read-file-name "Select image to attach: ")))
      (when selected-item
        (let ((source-file
               (cond
                ((listp selected-item) (car selected-item))
                ((stringp selected-item) selected-item)
                (t (format "%s" selected-item)))))
          (setq source-file (expand-file-name source-file))
          (if (and source-file (file-exists-p source-file))
              (progn
                (org-attach-attach source-file)
                (insert (format "[[attachment:%s]]\n"
                                (file-name-nondirectory source-file)))
                (when (fboundp 'org-display-inline-images)
                  (org-display-inline-images))
                (message "File '%s' attached successfully."
                         (file-name-nondirectory source-file)))
            (error "File does not exist: %s" source-file))))))

  (defun coffee-new-bean ()
    "Capture a new coffee bean."
    (interactive)
    (org-capture nil (concat coffee--capture-key "n")))

  (defun coffee-new-batch ()
    "Capture a new roasted batch."
    (interactive)
    (org-capture nil (concat coffee--capture-key "b")))

  (defun coffee-new-brew ()
    "Capture a detailed brew record."
    (interactive)
    (org-capture nil (concat coffee--capture-key "r")))

  (defun coffee-new-cafe ()
    "Capture a cafe drink record."
    (interactive)
    (org-capture nil (concat coffee--capture-key "c")))

  (defun coffee-export-to-html ()
    "Export coffee tastings to an interactive HTML table."
    (interactive)
    (let ((data nil)
          (html-file (expand-file-name "coffee-tastings.html" coffee-project-dir)))
      ;; 收集数据
      (with-current-buffer (find-file-noselect coffee-log-file)
        (org-map-entries
         (lambda ()
           (let ((date (org-entry-get nil "TASTED_DATE")))
             (when date
               (let ((tasting-notes-props nil)
                     (tasting-notes-text nil))
                 (save-excursion
                   (when (re-search-forward "^\\*\\*\\*\\* Tasting Notes"
                                            (save-excursion (org-end-of-subtree t t)) t)
                     (setq tasting-notes-props
                           (list :aroma (org-entry-get nil "AROMA")
                                 :acidity (org-entry-get nil "ACIDITY")
                                 :sweetness (org-entry-get nil "SWEETNESS")
                                 :body (org-entry-get nil "BODY")
                                 :aftertaste (org-entry-get nil "AFTERTASTE")
                                 :balance (org-entry-get nil "BALANCE")))
                     (when (re-search-forward ":END:" nil t)
                       (forward-line 1)
                       (let ((start (point)))
                         (if (re-search-forward "^\\*\\*\\*\\* " nil t)
                             (beginning-of-line)
                           (org-end-of-subtree t t))
                         (setq tasting-notes-text
                               (string-trim (buffer-substring-no-properties start (point))))))))
                 (push (list
                        :date date
                        :literally (org-entry-get nil "LITERALLY" t)
                        :price (org-entry-get nil "DRINK_PRICE")
                        :origin (org-entry-get nil "ORIGIN" t)
                        :region (org-entry-get nil "REGION" t)
                        :method (org-entry-get nil "BREW_METHOD")
                        :style (org-entry-get nil "BREW_STYLE")
                        :aroma (plist-get tasting-notes-props :aroma)
                        :acidity (plist-get tasting-notes-props :acidity)
                        :sweetness (plist-get tasting-notes-props :sweetness)
                        :body (plist-get tasting-notes-props :body)
                        :aftertaste (plist-get tasting-notes-props :aftertaste)
                        :balance (plist-get tasting-notes-props :balance)
                        :notes tasting-notes-text)
                       data)))))
         "TASTED_DATE<>\"\""
         'file))

      ;; 生成HTML
      (with-temp-file html-file
        (insert "<!DOCTYPE html>
<html lang=\"zh-CN\">
<head>
    <meta charset=\"UTF-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">
    <title>Coffee Tasting Log</title>
    <link href=\"https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css\" rel=\"stylesheet\">
    <script src=\"https://code.jquery.com/jquery-3.7.0.js\"></script>
    <script src=\"https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js\"></script>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Helvetica, Arial, sans-serif;
            line-height: 1.5;
            color: #333;
            background-color: #fff;
            margin: 0;
            padding: 20px;
        }
        .container {
            max-width: 1600px;
            margin: 0 auto;
        }
        h1 {
            font-size: 2em;
            padding-bottom: .3em;
            border-bottom: 1px solid #ddd;
            margin-bottom: 20px;
        }
        table.dataTable {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #ddd;
        }
        table.dataTable thead {
            background-color: #f8f8f8;
        }
        table.dataTable th,
        table.dataTable td {
            padding: 8px 12px;
            border: 1px solid #ddd;
            text-align: left;
        }
        table.dataTable tbody tr:nth-child(odd) {
            background-color: #fff;
        }
        table.dataTable tbody tr:nth-child(even) {
            background-color: #f8f8f8;
        }
        table.dataTable tbody tr:hover {
            background-color: #f0f0f0;
        }
        .notes {
            max-width: 300px;
            white-space: pre-wrap;
            word-wrap: break-word;
        }
        .rating {
            text-align: center;
        }
    </style>
</head>
<body>
    <div class=\"container\">
        <h1>☕ Coffee Tasting Log</h1>
        <table id=\"coffeeTable\" class=\"display\" style=\"width:100%\">
            <thead>
                <tr>
                    <th>日期</th>
                    <th>咖啡豆</th>
                    <th>价格</th>
                    <th>产地</th>
                    <th>产区</th>
                    <th>冲煮</th>
                    <th>风格</th>
                    <th>香气</th>
                    <th>酸度</th>
                    <th>甜度</th>
                    <th>醇厚</th>
                    <th>余韵</th>
                    <th>平衡</th>
                    <th>品尝笔记</th>
                </tr>
            </thead>
            <tbody>\n")

        ;; 插入数据行
        (let ((rows (reverse data)))
          (while rows
            (let* ((row (car rows))
                   (date-raw (or (plist-get row :date) ""))
                   (date-str (if (> (length date-raw) 10)
                                 (substring date-raw 1 11)
                               date-raw))
                   (aroma (plist-get row :aroma))
                   (acidity (plist-get row :acidity))
                   (sweetness (plist-get row :sweetness))
                   (body (plist-get row :body))
                   (aftertaste (plist-get row :aftertaste))
                   (balance (plist-get row :balance)))
              (insert (format "                <tr>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td>%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"rating\">%s</td>
                    <td class=\"notes\">%s</td>
                </tr>\n"
                              date-str
                              (or (plist-get row :literally) "")
                              (or (plist-get row :price) "")
                              (or (plist-get row :origin) "")
                              (or (plist-get row :region) "")
                              (or (plist-get row :method) "")
                              (or (plist-get row :style) "")
                              (if (and aroma (not (string-empty-p aroma))) aroma "-")
                              (if (and acidity (not (string-empty-p acidity))) acidity "-")
                              (if (and sweetness (not (string-empty-p sweetness))) sweetness "-")
                              (if (and body (not (string-empty-p body))) body "-")
                              (if (and aftertaste (not (string-empty-p aftertaste))) aftertaste "-")
                              (if (and balance (not (string-empty-p balance))) balance "-")
                              (or (plist-get row :notes) ""))))
            (setq rows (cdr rows))))

        (insert "            </tbody>
        </table>
    </div>
    <script>
        $(document).ready(function() {
            $('#coffeeTable').DataTable({
                paging: false,
                language: {
                    search: \"搜索:\",
                    lengthMenu: \"显示 _MENU_ 条\",
                    info: \"共 _TOTAL_ 条记录\",
                    emptyTable: \"暂无数据\",
                    zeroRecords: \"没有找到匹配的记录\"
                },
                order: [[0, 'desc']],
                columnDefs: [
                    { width: '80px', targets: 0 },
                    { width: '200px', targets: 1 },
                    { width: '60px', targets: 2 },
                    { width: '80px', targets: 3 },
                    { width: '100px', targets: 4 },
                    { width: '80px', targets: 5 },
                    { width: '100px', targets: 6 },
                    { width: '40px', targets: [7,8,9,10,11,12] },
                    { width: '300px', targets: 13 }
                ]
            });
        });
    </script>
</body>
</html>"))

      (browse-url html-file)
      (message "Exported to %s" html-file)))

  ;;; ---- Capture 模板常量 ----
  ;;; 完全匹配实际文件结构

  (defconst coffee--template-new-bean
    (concat "* %^{NAME: Bean Name}\n"
            ":PROPERTIES:\n"
            ":ID: BEAN-%<%Y-%m-%dT%H.%M>\n"
            ":LITERALLY: %^{LITERALLY: Exact text from the label}\n"
            ":NAME: %\\1\n"
            ":ORIGIN: %^{ORIGIN: Country|Unknown}\n"
            ":REGION: %^{REGION: Region|Unknown}\n"
            ":FARM_COOP: %^{FARM_COOP: Farm/Coop/Station|Unknown}\n"
            ":VARIETY: %^{VARIETY|Unknown|Gesha|Bourbon|Typica|Caturra|Catuai|SL28|SL34|Heirloom|Pacamara|Java|Other}\n"
            ":PROCESS: %^{PROCESS|Unknown|Washed|Natural|Honey|Anaerobic|Anaerobic Honey|Carbonic Maceration|Other}\n"
            ":ALTITUDE: %^{ALTITUDE|Unknown}\n"
            ":HARVEST_YEAR: %^{HARVEST_YEAR|Unknown|2025|2024|2023|2022}\n"
            ":END:\n\n"
            "%?"))

  (defconst coffee--template-new-batch
    (concat "** [%<%Y-%m-%d>]\n"
            ":PROPERTIES:\n"
            ":ID: BATCH-%<%Y-%m-%d>\n"
            ":ROASTER: %^{ROASTER|Unknown}\n"
            ":ROAST_PROFILE: %^{ROAST_PROFILE|Unknown|Filter|Espresso|Omni}\n"
            ":ROAST_LEVEL: %^{ROAST_LEVEL|Unknown|Light|Light-Medium|Medium|Medium-Dark|Dark}\n"
            ":ROAST_DATE: %^{ROAST_DATE|Unknown}\n"
            ":PURCHASE_DATE: %^{PURCHASE_DATE|Unknown}\n"
            ":VENDOR: %^{VENDOR|Unknown}\n"
            ":ROASTED_BEAN_PRICE: %^{ROASTED_BEAN_PRICE|Unknown}\n"
            ":END:\n\n"
            "%?"))

  (defconst coffee--template-brew-record
    (concat "*** [%<%Y-%m-%d %H:%M>]\n"
            ":PROPERTIES:\n"
            ":ID: TASTING-%<%Y-%m-%dT%H.%M>\n"
            ":TASTED_DATE: [%<%Y-%m-%d %H:%M>]\n"
            ":DRINK_PRICE: %^{DRINK_PRICE|Unknown}\n"
            ":BREWER: %^{BREWER|Myself|Barista|Friend|M|F|Machine}\n"
            ":BREW_METHOD: %^{BREW_METHOD|V60|Chemex|AeroPress|French Press|Espresso|Cold Brew|Clever|Kalita Wave|Pour-over|Americano}\n"
            ":BREW_STYLE: %^{BREW_STYLE|Hot|Iced (Post-Brew)|Flash Brew|Ice}\n"
            ":GRINDER: %^{GRINDER|Unknown}\n"
            ":GRIND_SETTING: %^{GRIND_SETTING|Unknown}\n"
            ":DOSE: %^{DOSE|Unknown}\n"
            ":WATER: %^{WATER|Unknown}\n"
            ":WATER_TEMP: %^{WATER_TEMP|Unknown|93|90|85|95}\n"
            ":WATER_TYPE: %^{WATER_TYPE|Unknown|Filtered|Tap|Bottled|Third Wave Water}\n"
            ":BREW_TIME: %^{BREW_TIME|Unknown}\n"
            ":END:\n\n"
            "**** Tasting Notes\n"
            ":PROPERTIES:\n"
            ":AROMA: %^{AROMA (1-5)|Unknown}\n"
            ":ACIDITY: %^{ACIDITY (1-5)|Unknown}\n"
            ":SWEETNESS: %^{SWEETNESS (1-5)|Unknown}\n"
            ":BODY: %^{BODY (1-5)|Unknown}\n"
            ":AFTERTASTE: %^{AFTERTASTE (1-5)|Unknown}\n"
            ":BALANCE: %^{BALANCE (1-5)|Unknown}\n"
            ":END:\n\n"
            "%?\n\n"
            "**** Owner's Claims\n\n"
            "None\n\n"
            "**** Images :ATTACH:\n"))

  (defconst coffee--template-cafe-record
    (concat "*** [%<%Y-%m-%d %H:%M>] Cafe: %^{Cafe Name}\n"
            ":PROPERTIES:\n"
            ":ID: TASTING-%<%Y-%m-%dT%H.%M>\n"
            ":TASTED_DATE: [%<%Y-%m-%d %H:%M>]\n"
            ":DRINK_PRICE: %^{DRINK_PRICE}\n"
            ":BREWER: %^{BREWER|Barista|M|F|Machine}\n"
            ":BREW_METHOD: %^{BREW_METHOD|Pour-over|Americano|Espresso|Latte|Cappuccino|Flat White|Mocha|Cold Brew}\n"
            ":BREW_STYLE: %^{BREW_STYLE|Iced (Post-Brew)|Hot|Flash Brew|Ice}\n"
            ":MILK_TYPE: %^{MILK_TYPE|None|Whole|Skim|Oat|Soy|Almond}\n"
            ":END:\n\n"
            "**** Tasting Notes\n"
            ":PROPERTIES:\n"
            ":AROMA: %^{AROMA (1-5)|Unknown}\n"
            ":ACIDITY: %^{ACIDITY (1-5)|Unknown}\n"
            ":SWEETNESS: %^{SWEETNESS (1-5)|Unknown}\n"
            ":BODY: %^{BODY (1-5)|Unknown}\n"
            ":AFTERTASTE: %^{AFTERTASTE (1-5)|Unknown}\n"
            ":BALANCE: %^{BALANCE (1-5)|Unknown}\n"
            ":END:\n\n"
            "%?\n\n"
            "**** Owner's Claims\n\n"
            "None\n\n"
            "**** Images :ATTACH:\n"))

  ;;; ---- Capture 模板设置 ----

  (with-eval-after-load 'org-capture
    ;; 移除已有的 coffee 模板
    (setq org-capture-templates
          (let ((result nil)
                (tmp org-capture-templates))
            (while tmp
              (let ((item (car tmp)))
                (unless (and (stringp (car item))
                             (string-prefix-p coffee--capture-key (car item)))
                  (push item result)))
              (setq tmp (cdr tmp)))
            (nreverse result)))

    ;; 添加 coffee 模板
    (add-to-list 'org-capture-templates
                 `(,coffee--capture-key "☕ Coffee"))

    (add-to-list 'org-capture-templates
                 `(,(concat coffee--capture-key "n") "New Coffee Bean" entry
                   (file ,coffee-log-file)
                   ,coffee--template-new-bean
                   :empty-lines 1))

    (add-to-list 'org-capture-templates
                 `(,(concat coffee--capture-key "b") "New Roasted Batch" entry
                   (file+function ,coffee-log-file coffee--select-bean)
                   ,coffee--template-new-batch
                   :empty-lines 1))

    (add-to-list 'org-capture-templates
                 `(,(concat coffee--capture-key "r") "Brew Record" entry
                   (file+function ,coffee-log-file coffee--select-bean-then-batch)
                   ,coffee--template-brew-record
                   :empty-lines 1))

    (add-to-list 'org-capture-templates
                 `(,(concat coffee--capture-key "c") "Cafe Record" entry
                   (file+function ,coffee-log-file coffee--select-bean-then-batch)
                   ,coffee--template-cafe-record
                   :empty-lines 1)))

  ;;; ---- org-attach 配置 ----

  (with-eval-after-load 'org-attach
    (setq org-attach-store-link-p 'attached)
    (setq org-attach-preferred-new-method 'cp))

  ;;; ---- 属性继承配置 ----

  (let ((tmp '("LITERALLY" "NAME" "ORIGIN" "REGION")))
    (while tmp
      (unless (member (car tmp) org-use-property-inheritance)
        (add-to-list 'org-use-property-inheritance (car tmp)))
      (setq tmp (cdr tmp))))

  ;;; ---- 内联图片配置 ----

  (setq org-startup-with-inline-images t)
  (setq org-image-actual-width '(400))

  ;;; ---- find-file-hook 设置 ----

  (defun coffee--setup-attach-dir ()
    "Set local org-attach-id-dir for coffee log file."
    (let ((fn (buffer-file-name)))
      (when (and fn (string= (expand-file-name fn)
                             (expand-file-name coffee-log-file)))
        (setq-local org-attach-id-dir coffee-attach-dir))))

  (add-hook 'find-file-hook #'coffee--setup-attach-dir)

  ;;; ---- 目录初始化 ----

  (unless (file-exists-p coffee-project-dir)
    (make-directory coffee-project-dir t))
  (unless (file-exists-p coffee-attach-dir)
    (make-directory coffee-attach-dir t))
  (unless (file-exists-p coffee-log-file)
    (with-temp-file coffee-log-file
      (insert "#+TITLE: Coffee Tasting Log\n"
              "#+AUTHOR: " (or user-full-name "Coffee Lover") "\n"
              "#+STARTUP: overview inlineimages\n"
              "#+COLUMNS: %25LITERALLY %15ORIGIN %15REGION %17TASTED_DATE %12DRINK_PRICE %12BREW_METHOD %12BREW_STYLE\n\n")))

  ) ;; End of with-eval-after-load 'org

;;; ---- Transient 菜单（可选） ----

(with-eval-after-load 'transient
  (transient-define-prefix coffee-menu ()
    "Coffee Tasting Log Management"
    ["Coffee Actions"
     ["Capture"
      ("n" "New Bean" coffee-new-bean)
      ("b" "New Batch" coffee-new-batch)
      ("r" "Brew Record" coffee-new-brew)
      ("c" "Cafe Record" coffee-new-cafe)]
     ["View"
      ("o" "Open Log" coffee-open-log)
      ("e" "Export to HTML" coffee-export-to-html)]
     ["Insert"
      ("i" "Insert Image" coffee-insert-image)]]))