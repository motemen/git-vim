function! GitBranch()
    let head_file = '.git/HEAD'
    if !filereadable(head_file) | return '' | endif
    let lines = readfile(head_file)
    return len(lines) ? matchstr(lines[0], '[^/]*$') : ''
endfunction

function! ListGitBranches(arg_lead, cmd_line, cursor_pos)
    let branchs = split(system('git branch'))
    if branchs[0] == 'fatal:'
        let branches = []
    else
        let branches = filter(split(system('git branch')), 'v:val != "*"')
    endif
    return branches
endfunction

command! -nargs=1 -complete=customlist,ListGitBranches GitCheckout :silent !git checkout <args>
