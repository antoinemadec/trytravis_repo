"This script holds miscellaneous functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Initialize
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"Store registers, initialize script vars and temporary buffer mappings.
"Some functions are registered in s:Funcs, that is returned to the global
"script, and then included in the global variable, so that they can be
"accessed from anywhere.

fun! vm#funcs#init()
    let s:V = b:VM_Selection | let s:v = s:V.Vars | let s:Global = s:V.Global
    let s:V.Funcs = s:Funcs

    call vm#maps#start()

    let s:v.def_reg = s:default_reg()
    let s:v.oldreg = s:Funcs.get_reg()
    let s:v.oldsearch = [getreg("/"), getregtype("/")]
    let s:v.oldvirtual = &virtualedit
    set virtualedit=onemore
    let s:v.oldwhichwrap = &whichwrap
    set ww=<,>,h,l

    let s:v.search = []
    let s:v.move_from_back = 0
    let s:v.ignore_case = 0
    let s:v.index = -1
    let s:v.direction = 1
    let s:v.silence = 0
    let s:v.only_this = 0
    let s:v.only_this_all = 0

    call s:augroup_start()
    return s:Funcs
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Reset
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#reset()
    let &virtualedit = s:v.oldvirtual
    let &whichwrap = s:v.oldwhichwrap
    call s:restore_regs()
    call vm#maps#end()
    let b:VM_Selection = {}
    call s:augroup_end()
    call clearmatches()
    set nohlsearch
    "call garbagecollect()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Funcs = {}

fun! s:default_reg()
    let clipboard_flags = split(&clipboard, ',')
    if index(clipboard_flags, 'unnamedplus') >= 0
        return "+"
    elseif index(clipboard_flags, 'unnamed') >= 0
        return "*"
    else
        return "\""
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Funcs.get_reg() dict
    let r = s:v.def_reg
    return [r, getreg(r), getregtype(r)]
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
fun! s:Funcs.set_reg(text) dict
    let r = s:v.def_reg
    call setreg(r, a:text, 'v')
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:restore_regs()
    let r = s:v.oldreg | let s = s:v.oldsearch
    call setreg(r[0], r[1], r[2])
    call setreg("/", s[0], s[1])
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:Funcs.msg(text) dict
    if !s:v.silence
        echohl WarningMsg
        echo a:text
        echohl None
    endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Search
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! vm#funcs#update_search()
    let r = s:Global.is_region_at_pos('.')
    if empty(r) | return | endif
    call s:update_search(escape(r.txt, '\|'), 1)
endfun

fun! s:Funcs.set_search() dict
    call s:update_search(s:pattern(), 0)
endfun

fun! s:update_search(p, update)

    if empty(s:v.search)
        call insert(s:v.search, a:p)       "just started

    elseif a:update                     "updating a match

        "if there's a match that is a substring of
        "the selected text, replace it with the new one
        let i = 0
        for p in s:v.search
            if a:p =~ p
                let s:v.search[i] = a:p
                break | endif
            let i += 1
        endfor

    elseif index(s:v.search, a:p) < 0   "not in list

        call insert(s:v.search, a:p)
    endif

    let @/ = join(s:v.search, '\|')
    set hlsearch
    call s:Funcs.msg('Current search: '.string(s:v.search))
endfun

fun! s:pattern()
    let t = eval('@'.s:v.def_reg)
    let t = escape(t, '\|')
    let t = substitute(t, '\n', '\\n', 'g')
    if s:v.whole_word | let t = '\<'.t.'\>' | endif
    return t
endfun

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocommands
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:augroup_start()
    augroup plugin-visual-multi
        au!
        au CursorMoved * call vm#commands#move()
    augroup END
endfun

fun! s:augroup_end()
    augroup plugin-visual-multi
        au!
    augroup END
endfun

