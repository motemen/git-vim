runtime syntax/diff.vim
set filetype=

syntax match gitStatusUndracked +^#\t\zs.\++
syntax match gitStatusNewFile   +^#\t\zsnew file: .\++
syntax match gitStatusModified  +^#\t\zsmodified: .\++

highlight link gitStatusUndracked   diffOnly
highlight link gitStatusNewFile     diffAdded
highlight link gitStatusModified    diffChanged
