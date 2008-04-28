if !exists('g:git_command_edit')
    let g:git_command_edit = 'new'
endif

if !exists('g:git_bufhidden')
    let g:git_bufhidden = ''
endif

nnoremap <Leader>gd :GitDiff<Enter>
nnoremap <Leader>gD :GitDiff!<Enter>
nnoremap <Leader>gs :GitStatus<Enter>
nnoremap <Leader>ga :GitAdd<Enter>

" Returns current git branch.
" Call inside 'statusline' or 'titlestring'.
function! GitBranch()
    if !exists('b:git_head_path')
        let dir = matchstr(expand('%:p'), '.*\ze[\\/]')
        while strlen(dir)
            if filereadable(dir . '/.git/HEAD')
                let b:git_head_path = dir . '/.git/HEAD'
                break
            endif
            let dir = matchstr(dir, '.*\ze[\\/]')
        endwhile
        if !exists('b:git_head_path')
            let b:git_head_path = ''
        endif
    endif
    if strlen(b:git_head_path)
        let lines = readfile(b:git_head_path)
        return len(lines) ? matchstr(lines[0], '[^/]*$') : ''
    else
        return ''
    endif
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

    set buftype=nofile
    execute 'set bufhidden=' . g:git_bufhidden

    silent 0put=a:content

    let b:is_git_msg_buffer = 1
endfunction

command! -nargs=1 -complete=customlist,ListGitBranches GitCheckout :silent !git checkout <args>
command! -bang GitDiff    :call GitDiff('<bang>')
command! GitStatus  :call GitStatus()
command! GitAdd     :call GitAdd()
