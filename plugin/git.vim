if !exists('g:git_command_edit')
    let g:git_command_edit = 'new'
endif

if !exists('g:git_bufhidden')
    let g:git_bufhidden = ''
endif

nnoremap <Leader>gd :GitDiff<Enter>
nnoremap <Leader>gD :GitDiff --cached<Enter>
nnoremap <Leader>gs :GitStatus<Enter>
nnoremap <Leader>gl :GitLog<Enter>
nnoremap <Leader>ga :GitAdd<Enter>
nnoremap <Leader>gA :GitAdd <cfile><Enter>
nnoremap <Leader>gc :GitCommit<Enter>

" Ensure b:git_dir exists.
function! s:GetGitDir()
    if !exists('b:git_dir')
        let b:git_dir = finddir('.git', expand('%:p:h') . ';/')
        if strlen(b:git_dir)
            let b:git_dir = fnamemodify(b:git_dir, ':p')
        endif
    endif
    return b:git_dir
endfunction

" Returns current git branch.
" Call inside 'statusline' or 'titlestring'.
function! GitBranch()
    let git_dir = <SID>GetGitDir()

    if strlen(git_dir) && filereadable(git_dir . 'HEAD')
        let lines = readfile(git_dir . 'HEAD')
        return len(lines) ? matchstr(lines[0], '[^/]*$') : ''
    else
        return ''
    endif
endfunction

" List all git local branches.
function! ListGitBranches(arg_lead, cmd_line, cursor_pos)
    let branches = split(system('git branch'), '\n')
    if v:shell_error
        return []
    endif

    return map(branches, 'matchstr(v:val, ''^[* ] \zs.*'')')
endfunction

" List all git commits.
function! ListGitCommits(arg_lead, cmd_line, cursor_pos)
    let commits = split(system('git log --pretty=format:%h'))
    if v:shell_error
        return []
    endif

    let commits = ['HEAD'] + ListGitBranches(a:arg_lead, a:cmd_line, a:cursor_pos) + commits

    if a:cmd_line =~ '^GitDiff'
        " GitDiff accepts <commit>..<commit>
        if a:arg_lead =~ '\.\.'
            let pre = matchstr(a:arg_lead, '.*\.\.\ze')
            let commits = map(commits, 'pre . v:val')
        endif
    endif

    return filter(commits, 'match(v:val, ''\v'' . a:arg_lead) == 0')
endfunction

" Show diff.
function! GitDiff(args)
    let git_output = system('git diff ' . a:args . ' -- ' . s:Expand('%'))
    if !strlen(git_output)
        echo "No output from git command"
        return
    endif

    call <SID>OpenGitBuffer(git_output)
    setlocal filetype=git-diff
endfunction

" Show Status.
function! GitStatus()
    let git_output = system('git status')
    call <SID>OpenGitBuffer(git_output)
    setlocal filetype=git-status
    nnoremap <buffer> <Enter> :GitAdd <cfile><Enter>:call <SID>RefreshGitStatus()<Enter>
    nnoremap <buffer> -       :silent !git reset HEAD -- =expand('<cfile>')<Enter><Enter>:call <SID>RefreshGitStatus()<Enter>
endfunction

function! s:RefreshGitStatus()
    let pos_save = getpos('.')
    GitStatus
    call setpos('.', pos_save)
endfunction

" Show Log.
function! GitLog(args)
    let git_output = system('git log ' . a:args . ' -- ' . s:Expand('%'))
    call <SID>OpenGitBuffer(git_output)
    setlocal filetype=git-log
endfunction

" Add file to index.
function! GitAdd(expr)
    let file = s:Expand(strlen(a:expr) ? a:expr : '%')

    call GitDoCommand('add ' . file)
endfunction

" Commit.
function! GitCommit(args)
    let git_dir = <SID>GetGitDir()

    " Create COMMIT_EDITMSG file
    let editor_save = $EDITOR
    let $EDITOR = ''
    call system('git commit ' . a:args)
    let $EDITOR = editor_save

    execute printf('%s %sCOMMIT_EDITMSG', g:git_command_edit, git_dir)
    setlocal filetype=git-status bufhidden=wipe
    augroup GitCommit
        autocmd BufWritePre  <buffer> g/^#\|^\s*$/d | setlocal fileencoding=utf-8
        execute printf("autocmd BufWritePost <buffer> call GitDoCommand('commit %s -F ' . expand('%%')) | autocmd! GitCommit * <buffer>", a:args)
    augroup END
endfunction

" Checkout.
function! GitCheckout(args)
    call GitDoCommand('checkout ' . a:args)
endfunction

" Show commit, tree, blobs.
function! GitCatFile(file)
    let file = s:Expand(a:file)
    "let file_type  = system('git cat-file -t ' . file)
    let git_output = system('git cat-file -p ' . file)
    if !strlen(git_output)
        echo "No output from git command"
        return
    endif

    call <SID>OpenGitBuffer(git_output)
endfunction

function! GitDoCommand(args)
    let git_output = system('git ' . a:args)
    let git_output = substitute(git_output, '\n*$', '', '')
    if v:shell_error
        echohl Error
        echo git_output
        echohl None
    else
        echo git_output
    endif
endfunction

" Show vimdiff for merge. (experimental)
function! GitVimDiffMerge()
    let file = s:Expand('%')
    let filetype = &filetype
    let t:git_vimdiff_original_bufnr = bufnr('%')
    let t:git_vimdiff_buffers = []

    topleft new
    setlocal buftype=nofile
    file `=':2:' . file`
    call add(t:git_vimdiff_buffers, bufnr('%'))
    execute 'silent read!git show :2:' . file
    0d
    diffthis
    let &filetype = filetype

    rightbelow vnew
    setlocal buftype=nofile
    file `=':3:' . file`
    call add(t:git_vimdiff_buffers, bufnr('%'))
    execute 'silent read!git show :3:' . file
    0d
    diffthis
    let &filetype = filetype
endfunction

function! GitVimDiffMergeDone()
    if exists('t:git_vimdiff_original_bufnr') && exists('t:git_vimdiff_buffers')
        if getbufline(t:git_vimdiff_buffers[0], 1, '$') == getbufline(t:git_vimdiff_buffers[1], 1, '$')
            execute 'sbuffer ' . t:git_vimdiff_original_bufnr
            0put=getbufline(t:git_vimdiff_buffers[0], 1, '$')
            normal! jdG
            update
            execute 'bdelete ' . t:git_vimdiff_buffers[0]
            execute 'bdelete ' . t:git_vimdiff_buffers[1]
            close
        else
            echohl Error
            echo 'There still remains conflict'
            echohl None
        endif
    endif
endfunction

function! s:OpenGitBuffer(content)
    if exists('b:is_git_msg_buffer') && b:is_git_msg_buffer
        enew!
    else
        execute g:git_command_edit
    endif

    setlocal buftype=nofile readonly modifiable
    execute 'setlocal bufhidden=' . g:git_bufhidden

    silent put=a:content
    keepjumps 0d
    setlocal nomodifiable

    let b:is_git_msg_buffer = 1
endfunction

function! s:Expand(expr)
    if has('win32')
        return substitute(expand(a:expr), '\', '/', 'g')
    else
        return expand(a:expr)
    endif
endfunction

command! -nargs=1 -complete=customlist,ListGitCommits GitCheckout call GitCheckout(<q-args>)
command! -nargs=* -complete=customlist,ListGitCommits GitDiff     call GitDiff(<q-args>)
command!          GitStatus           call GitStatus()
command! -nargs=? GitAdd              call GitAdd(<q-args>)
command! -nargs=* GitLog              call GitLog(<q-args>)
command! -nargs=* GitCommit           call GitCommit(<q-args>)
command! -nargs=1 GitCatFile          call GitCatFile(<q-args>)
command! -nargs=+ Git                 call GitDoCommand(<q-args>)
command!          GitVimDiffMerge     call GitVimDiffMerge()
command!          GitVimDiffMergeDone call GitVimDiffMergeDone()
