""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Global class
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let s:Global = {}

fun! vm#global#init()
    let s:V       = b:VM_Selection

    let s:v       = s:V.Vars
    let s:Regions = s:V.Regions

    let s:Funcs   = s:V.Funcs
    let s:Search  = s:V.Search
    let s:Edit    = s:V.Edit

    let s:X       = { -> g:VM.extend_mode }

    return s:Global
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.get_region() dict
    """Get the region under cursor, or create a new one if there is none."""

    let R = self.is_region_at_pos('.')
    if empty(R) | let R = vm#region#new(0) | endif

    let s:v.matches = getmatches()
    call self.select_region(R.index)
    call s:Search.check_pattern()
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.new_cursor() dict
    """Create a new cursor if there is't already a region."""

    let r = self.is_region_at_pos('.')
    if !empty(r) | return r | endif

    let R = vm#region#new(1)

    let s:v.matches = getmatches()
    return R
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_highlight(...) dict
    """Update highlight for all regions."""

    for r in s:Regions
        call r.update_highlight()
    endfor

    call setmatches(s:v.matches)
    call self.update_cursor_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_cursor_highlight(...) dict
    """Set cursor highlight, depending on extending mode."""

    highlight clear MultiCursor
    if !s:X() && self.all_empty()
        exe "highlight link MultiCursor ".g:VM_Mono_Cursor_hl
    else
        exe "highlight link MultiCursor ".g:VM_Normal_Cursor_hl
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Regions functions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.all_empty() dict
    """If not all regions are empty, turn on extend mode, if not already active.

    for r in s:Regions
        if r.a != r.b
            if !s:X() | call vm#commands#change_mode(0) | endif
            return 0  | endif
    endfor
    return 1
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_regions() dict
    """Force regions update."""

    for r in s:Regions | call r.update() | endfor
    call self.update_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.collapse_regions() dict
    """Collapse regions to cursors and turn off extend mode."""

    for r in s:Regions
        if r.A != r.B | call r.update(r.l, r.L, r.a, r.a) | endif
    endfor
    let g:VM.extend_mode = 0
    "call self.update_regions()
    call self.update_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.split_lines() dict
    """When switching off multiline, split selections, so that each is
    "contained in a single line."""

    "make a list of regions to split
    let lts = []
    for r in s:Regions | if r.h | call add(lts, r.index) | endif | endfor

    for i in lts
        let R = s:Regions[i].remove

        for n in range(R.h)
            if n == 0  "first line
                call vm#region#new(0, R.l, R.L, R.a, len(getline(R.l)))
            elseif n != R.h
                call vm#region#new(0, R.l, R.L, 1, len(getline(R.l)))
            else
                call vm#region#new(0, R.l, R.L, 1, R.b)
            endif
            let s:v.matches = getmatches()
        endfor
    endfor

    "reorder regions when done
    call self.reorder_regions()
    call self.update_highlight()
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.reorder_regions() dict
    """Reorder regions, so that their byte offsets are consecutive."""

    let Regions = [s:Regions[0]]
    let Matches = [s:Matches[0]]
    let offsets = {}
    for 
    let offsets = map(s:Regions, 'v:val.A')
    for r in s:Regions[1:]
        if r.A > s:Regions[r.index-1]
            call add(Regions, r)
            call add(Matches, s:Matches[r.index])
        elseif r.A > s:Regions[r.index-1]
            call insert(Regions, r)
            call insert(Matches, s:Matches[r.index])
        endif
    endfor
    let s:Regions = Regions
    let s:Matches = Matches
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region(i) dict
    """Adjust cursor position of the region at index, then return the region."""

    if a:i >= len(s:Regions) | let i = 0
    elseif a:i<0 | let i = len(s:Regions) - 1
    else | let i = a:i | endif

    let R = s:Regions[i]
    call cursor(R.cur_ln(), R.cur_col())
    let s:v.index = i
    return R
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.select_region_at_pos(pos) dict
    """Try to select a region at the given position."""

    let r = self.is_region_at_pos(a:pos)
    if !empty(r)
        return self.select_region(r.index)
    endif
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.is_region_at_pos(pos) dict
    """Find if the cursor is on a highlighted region.
    "Return an empty dict otherwise."""

    let pos = s:Funcs.pos2byte(a:pos)

    for r in s:Regions
        if pos >= r.A && pos <= r.B
            return r | endif | endfor
    return {}
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_region_patterns(pat) dict
    """Update the patterns for the appropriate regions."""

    for r in s:Regions
        if a:pat =~ r.pat || r.pat =~ a:pat
            let r.pat = a:pat
        endif
    endfor
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.update_indices() dict
    """Adjust region indices."""

    let i = 0
    for r in s:Regions
        let r.index = i
        let i += 1
    endfor
endfun


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Merging regions
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.merge_cursors()
    """BROKEN: Merge overlapping cursors."""

    let cursors_pos = map(s:Regions, 'v:val.A')
    "echom string(cursors_pos)
    while 1
        let i = 0
        for c in cursors_pos
            if count(cursors_pos, c) > 1
                call s:Regions[i].remove() | break | endif
            let i += 1
        endfor
        break
    endwhile
endfun

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

fun! s:Global.merge_regions(...) dict
    """MUST BE IMPROVED: Merge overlapping regions."""

    let lines = {}
    let storepos = getpos('.')

    "find lines with regions
    for r in s:Regions
        "called a merge for a specific line
        if a:0 && r.l != a:1 | continue | endif
        "add region index to indices for that line
        let lines[r.l] = get(lines, r.l, [])
        call add(lines[r.l], r.index)
    endfor

    "remove lines and indices without multiple regions
    let lines = filter(lines, 'len(v:val) > 1')
    let to_remove = []

    "find overlapping regions for each line with multiple regions
    for indices in values(lines)
        let n = 0 | let max = len(indices) - 1

        for i in indices
            while (n < max)
                let i1 = indices[n] | let i2 = indices[n+1] | let n += 1
                let this = s:Regions[i1] | let next = s:Regions[i2]

                let overlap = ( this.B >= next.A ) && ( this.A <= next.A ) ||
                            \ ( next.B >= this.A ) && ( next.A <= this.A )

                "merge regions if there is overlap with next one
                if overlap
                    call next.update(this.l, this.L, min([this.a, next.a]), max([this.b, next.b]))
                    call add(to_remove, this)
                endif | endwhile | endfor | endfor

    " remove old regions and update highlight
    for r in to_remove | call r.remove() | endfor
    call self.update_highlight()

    "restore cursor position
    call self.select_region_at_pos(storepos)
endfun

