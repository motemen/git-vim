if !exists('g:git_command_edit')
    let g:git_command_edit = 'new'
endif

nnoremap <Leader>gd :GitDiff<Enter>
nnoremap <Leader>gD :GitDiff!<Enter>
nnoremap <Leader>gs :GitStatus<Enter>
nnoremap <Leader>ga :GitAdd<Enter>

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
function! GitDiff(cached)
    let git_output = system('git diff ' . (a:cached == '!' ? '--cached ' : '') . expand('%'))
    if !strlen(git_output)
        echo "no output from git command"
        return
    endif

    call <SID>OpenGitBuffer(git_output)
    set filetype=diff
endfunction

" Show Status.
function! GitStatus()
    let git_output = system('git status')
    call <SID>OpenGitBuffer(git_output)
    set filetype=git-status
endfunction

" Add file to index.
function! GitAdd()
    silent !git add %
endfunction

function! s:OpenGitBuffer(content)
    if exists('b:is_git_msg_buffer') && b:is_git_msg_buffer
        enew!
    else
        execute g:git_command_edit
    endif

    set buftype=nofile bufhidden=delete

    silent 0put=a:content

    let b:is_git_msg_buffer = 1
endfunction

command! -nargs=1 -complete=customlist,ListGitBranches GitCheckout :silent !git checkout <args>
command! -bang GitDiff    :call GitDiff('<bang>')
command! GitStatus  :call GitStatus()
command! GitAdd     :call GitAdd()
