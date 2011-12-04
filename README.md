# ac-rsense-expand
EmacsでRsenseを利用する際、補完したメソッドを
yasnippetで展開するためのEmacs設定及びsnippet群です。

## Requirements
* auto-complete
* Rsense
* yasnippet

## Installation
auto-complete, Rsense, yasnippetの設定は行われていることを前提とします。
1. ac-rsense-yas-expand/snippetsディレクトリ以下をすでに設定しているyasnippetのsnippetに追加してください。
            
2. Emacsの設定ファイル(.emacs.el, .emacs.d/init.el等)に下記を追記してください。
ac-source-rsenseを元々ac-sourceに追加している場合は削除してください。

            (require 'ac-rsense-yas-expand)
            (add-hook 'ruby-mode-hook
               (lambda ()
                  (setq ac-sources (append '(ac-source-rsense-yas) ac-sources))))