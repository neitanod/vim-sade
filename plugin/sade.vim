if exists("sade#Loaded")
    finish
endif
let sade#Loaded = 1

let g:sade#Defined = {}

function! sade#Func(key, func)
  let g:sade#Defined[a:key]=a:func
  exe "nnoremap ".a:key." :call sade#HookNormal('".a:key."')<cr>g@"
  exe "vnoremap ".a:key." <esc>:call sade#HookVisual('".a:key."')<cr><esc>g@w"
endfun

function! sade#HookNormal(key)
  "echom "HookNormal"
  let g:sade#LastRun=a:key
  set opfunc=sade#RunNormal
endfun

function! sade#RunNormal(vt, ...)
  "echom "RunNormal"
  "echom "Visualmode: ".a:vt
  let g:sade#LastVt=a:vt
  
  " get target's coordinates
  let [sl, sc] = getpos(a:0?"'<":"'[")[1:2]
  let [el, ec] = getpos(a:0?"'>":"']")[1:2]

  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 

  let g:sade#StartingLine   = sl
  let g:sade#EndingLine     = el
  let g:sade#StartingColumn = sc
  let g:sade#EndingColumn   = ec

  if a:vt=='char' || a:vt=='v' 
    " our target is a text object or motion
    " visually select it
    call sade#GoToLineCol(sl, sc) 
    norm! v
    call sade#GoToLineCol(el, ec) 
  elseif a:vt=='line' || a:vt=='V'
    call sade#GoToLine(sl) 
    norm! V
    call sade#GoToLine(el) 
  elseif a:vt=='block' || a:vt=='<C-v>' || a:vt=='<c-v>'
    call sade#GoToLineCol(sl, sc) 
    exe 'norm! \<c-v>'
    call sade#GoToLineCol(el, ec) 
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:sade#LastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  exe "norm! \<esc>"
  norm! gv
  "echom 'call '.g:sade#Defined[g:sade#LastRun] .'()'
  exe 'call '.g:sade#Defined[g:sade#LastRun] .'()'
endfun

function! sade#HookVisual(key)
  "echom "HookVisual"
  let g:sade#LastRun=a:key
  let g:sade#Repeating=0
  let g:sade#LastVt=visualmode()
  "echom "Visualmode: ".g:sade#LastVt
  norm! m(om)

  " must leave visual mode so the markers get set
  exe "norm! \<esc>gv" 

  " get target's coordinates
  " target exists when hooking, not when invoking,
  " so we capture its geometry here
  let [sl, sc] = getpos("'<")[1:2]
  let [el, ec] = getpos("'>")[1:2]

  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 
  
  let g:sade#StartingLine   = sl
  let g:sade#EndingLine     = el
  let g:sade#StartingColumn = sc
  let g:sade#EndingColumn   = ec
  set opfunc=sade#RunVisual
endfun

function! sade#RunVisual(vt, ...)
  let vt=g:sade#LastVt
  "echom "RunVisual ".vt
  " we must rebuild the selection
  let sl = g:sade#StartingLine
  let el = g:sade#EndingLine
  let sc = g:sade#StartingColumn
  let ec = g:sade#EndingColumn
  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 
  if g:sade#Repeating==0
    exe 'norm! \<esc>'
    if vt=='char' || vt=='v' 
      " our target is a text object or motion
      " visually select it
      call sade#GoToLineCol(sl, sc) 
      norm! v
      call sade#GoToLineCol(el, ec) 
    elseif vt=='line' || vt=='V'
      call sade#GoToLine(sl) 
      norm! V
      call sade#GoToLine(el) 
    else    
      "vt=='block' || vt=='<C-v>' || vt=='<c-v>' || vt=='^V'
      call sade#GoToLineCol(sl, sc) 
      exe "norm! \<C-v>"
      call sade#GoToLineCol(el, ec) 
    endif
  else
    "echom "Repeating"
    " we are about to repeat a visual selection
    let lines = el - sl
    exe 'norm! \<esc>'
    exe 'norm! '.(vt=='v' || vt=='char'?'v':(vt=='V' || vt=='line'?'V':"\<C-v>"))
    call sade#GoToLine(line(".")+lines)
    "echom "Desde linea: ".line(".")
    "echom "Hasta linea: ".(line(".")+lines)
    call sade#MoveCols(ec-sc+1)
    "echom "Columnas: ".(ec-sc+1)
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:sade#LastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  "exe "norm! \<esc>"
  norm! gv
  let g:sade#Repeating=1
  exe 'call '.g:sade#Defined[g:sade#LastRun] .'()'
endfun

function! sade#GoToLineCol(l, c)
  call sade#GoToLine(a:l)
  call sade#GoToCol(a:c)
endfun

function! sade#GoToLine(l)
  if line(".") > a:l
    exe 'norm! '.(line(".") - a:l).'k'
  elseif line(".") < a:l
    exe 'norm! '.(a:l - line(".")).'j'
  endi
endfun

function! sade#MoveCols(n)
  "echom "a:n = ".a:n
  if(a:n > 1)
    exe 'norm! '.(a:n-1).'l'
  endif
endfun

function! sade#GoToCol(c)
  norm! 0
  call sade#MoveCols(a:c)
endfun

