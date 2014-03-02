if exists("UserOperatorLoaded")
    finish
endif
let UserOperatorLoaded = 1

let g:UserOperatorDefined = {}

function! UserOperatorFunc(key, func)
  let g:UserOperatorDefined[a:key]=a:func
  exe "nnoremap ".a:key." :call UserOperatorHookNormal('".a:key."')<cr>g@"
  exe "vnoremap ".a:key." :call UserOperatorHookVisual('".a:key."')<cr><esc>g@w"
endfun

function! UserOperatorHookNormal(key)
  echom "HookNormal"
  let g:UserOperatorLastRun=a:key
  set opfunc=UserOperatorRunNormal
endfun

function! UserOperatorRunNormal(vt, ...)
  echom "RunNormal"
  echom "Visualmode: ".a:vt
  let g:UserOperatorLastVt=a:vt
  
  " get target's coordinates
  let [sl, sc] = getpos(a:0?"'<":"'[")[1:2]
  let [el, ec] = getpos(a:0?"'>":"']")[1:2]

  echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 

  let g:UserOperatorStartingLine   = sl
  let g:UserOperatorEndingLine     = el
  let g:UserOperatorStartingColumn = sc
  let g:UserOperatorEndingColumn   = ec

  if a:vt=='char' || a:vt=='v' 
    " our target is a text object or motion
    " visually select it
    call UserOperatorGoToLineCol(sl, sc) 
    norm! v
    call UserOperatorGoToLineCol(el, ec) 
  elseif a:vt=='line' || a:vt=='V'
    call UserOperatorGoToLine(sl) 
    norm! V
    call UserOperatorGoToLine(el) 
  elseif a:vt=='block' || a:vt=='<C-v>' || a:vt=='<c-v>'
    call UserOperatorGoToLineCol(sl, sc) 
    exe 'norm! \<c-v>'
    call UserOperatorGoToLineCol(el, ec) 
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:UserOperatorLastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  exe "norm! \<esc>"
  norm! gv
  exe 'call '.g:UserOperatorDefined[g:UserOperatorLastRun] .'()'
endfun

function! UserOperatorHookVisual(key)
  echom "HookVisual"
  let g:UserOperatorLastRun=a:key
  let g:UserOperatorRepeating=0
  let g:UserOperatorLastVt=visualmode()
  echom "Visualmode: ".g:UserOperatorLastVt
  
  " must leave visual mode so the markers get set
  exe "norm! \<esc>gv" 

  " get target's coordinates
  " target exists when hooking, not when invoking,
  " so we capture its geometry here
  let [sl, sc] = getpos("'<")[1:2]
  let [el, ec] = getpos("'>")[1:2]

  echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 
  
  let g:UserOperatorStartingLine   = sl
  let g:UserOperatorEndingLine     = el
  let g:UserOperatorStartingColumn = sc
  let g:UserOperatorEndingColumn   = ec
  set opfunc=UserOperatorRunVisual
endfun

function! UserOperatorRunVisual(vt, ...)
  echom "RunVisual"
  let vt=g:UserOperatorLastVt
  " we must rebuild the selection
  let sl = g:UserOperatorStartingLine
  let el = g:UserOperatorEndingLine
  let sc = g:UserOperatorStartingColumn
  let ec = g:UserOperatorEndingColumn
  if g:UserOperatorRepeating==0
    exe 'norm! \<esc>'
    if vt=='char' || vt=='v' 
      " our target is a text object or motion
      " visually select it
      call UserOperatorGoToLineCol(sl, sc) 
      norm! v
      call UserOperatorGoToLineCol(el, ec) 
    elseif vt=='line' || vt=='V'
      call UserOperatorGoToLine(sl) 
      norm! V
      call UserOperatorGoToLine(el) 
    elseif vt=='block' || vt=='<C-v>' || vt=='<c-v>'
      call UserOperatorGoToLineCol(sl, sc) 
      exe 'norm! \<c-v>'
      call UserOperatorGoToLineCol(el, ec) 
    endif
  else
    echom "Repeating"
    " we are about to repeat a visual selection
    let lines = el - sl
    exe 'norm! \<esc>'
    exe 'norm! '.(vt=='v' || vt=='char'?'v':(vt=='V' || vt=='line'?'V':"\<C-v>"))
    call UserOperatorGoToLine(line(".")+lines)
    echom "Desde linea: ".line(".")
    echom "Hasta linea: ".(line(".")+lines)
    call UserOperatorMoveCols(ec-sc+1)
    echom "Columnas: ".(ec-sc+1)
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:UserOperatorLastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  exe "norm! \<esc>"
  norm! gv
  let g:UserOperatorRepeating=1
  exe 'call '.g:UserOperatorDefined[g:UserOperatorLastRun] .'()'
endfun

function! UserOperatorGoToLineCol(l, c)
  call UserOperatorGoToLine(a:l)
  call UserOperatorGoToCol(a:c)
endfun

function! UserOperatorGoToLine(l)
  if line(".") > a:l
    exe 'norm! '.(line(".") - a:l).'k'
  elseif line(".") < a:l
    exe 'norm! '.(a:l - line(".")).'j'
  endi
endfun

function! UserOperatorMoveCols(n)
  if(a:n > 1)
    exe 'norm! '.(a:n-1).'l'
  endif
endfun

function! UserOperatorGoToCol(c)
  norm! 0
  call UserOperatorMoveCols(a:c)
endfun

