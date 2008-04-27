if !exists('g:git_command_edit')
    let g:git_command_edit = 'new'
endif

nnoremap <Leader>gd :GitDiff<Enter>
nnoremap <Leader>gs :GitStatus<Enter>

" Returns current git branch.
" Call inside 'statusline' or 'titlestring'.
function! GitBranch()
    let head_file = '.git/HEAD'
    if !filereadable(head_file) | return '' | endif
    let lines = readfile(head_file)
    return len(lines) ? matchstr(lines[0], '[^/]*$') : ''
endfunction

" List all git local branches.
function! ListGitBranches(arg_lead, cmd_line, cursor_pos)
    let branchs = split(system('git branch'))
    if branchs[0] == 'fatal:'
        let branches = []
    else
        let branches = filter(split(system('git branch')), 'v:val != "*"')
    endif
    return branches
endfunction

" Show diff.
function! GitDiff()
    let git_output = system('git diff ' . expand('%'))
    if !strlen(git_output)
        echo "no output from git command"
        return
    endif

    execute g:git_command_edit
    set buftype=nofile filetype=diff bufhidden=delete
    silent 0put=git_output
endfunction

" Show Status.
function! GitStatus()
    let git_output = system('git status')
    execute g:git_command_edit
    set buftype=nofile filetype=git-status bufhidden=delete
    silent 0put=git_output
endfunction

command! -nargs=1 -complete=customlist,ListGitBranches GitCheckout :silent !git checkout <args>
command! GitDiff    :call GitDiff()
command! GitStatus  :call GitStatus()
