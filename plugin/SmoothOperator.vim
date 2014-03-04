if exists("SmoothOperator#Loaded")
    finish
endif
let SmoothOperator#Loaded = 1

let g:SmoothOperator#Defined = {}

function! SmoothOperator#Func(key, func)
  let g:SmoothOperator#Defined[a:key]=a:func
  exe "nnoremap ".a:key." :call SmoothOperator#HookNormal('".a:key."')<cr>g@"
  exe "vnoremap ".a:key." <esc>:call SmoothOperator#HookVisual('".a:key."')<cr><esc>g@w"
endfun

function! SmoothOperator#HookNormal(key)
  "echom "HookNormal"
  let g:SmoothOperator#LastRun=a:key
  set opfunc=SmoothOperator#RunNormal
endfun

function! SmoothOperator#RunNormal(vt, ...)
  "echom "RunNormal"
  "echom "Visualmode: ".a:vt
  let g:SmoothOperator#LastVt=a:vt
  
  " get target's coordinates
  let [sl, sc] = getpos(a:0?"'<":"'[")[1:2]
  let [el, ec] = getpos(a:0?"'>":"']")[1:2]

  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 

  let g:SmoothOperator#StartingLine   = sl
  let g:SmoothOperator#EndingLine     = el
  let g:SmoothOperator#StartingColumn = sc
  let g:SmoothOperator#EndingColumn   = ec

  if a:vt=='char' || a:vt=='v' 
    " our target is a text object or motion
    " visually select it
    call SmoothOperator#GoToLineCol(sl, sc) 
    norm! v
    call SmoothOperator#GoToLineCol(el, ec) 
  elseif a:vt=='line' || a:vt=='V'
    call SmoothOperator#GoToLine(sl) 
    norm! V
    call SmoothOperator#GoToLine(el) 
  elseif a:vt=='block' || a:vt=='<C-v>' || a:vt=='<c-v>'
    call SmoothOperator#GoToLineCol(sl, sc) 
    exe 'norm! \<c-v>'
    call SmoothOperator#GoToLineCol(el, ec) 
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:SmoothOperator#LastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  exe "norm! \<esc>"
  norm! gv
  "echom 'call '.g:SmoothOperator#Defined[g:SmoothOperator#LastRun] .'()'
  exe 'call '.g:SmoothOperator#Defined[g:SmoothOperator#LastRun] .'()'
endfun

function! SmoothOperator#HookVisual(key)
  "echom "HookVisual"
  let g:SmoothOperator#LastRun=a:key
  let g:SmoothOperator#Repeating=0
  let g:SmoothOperator#LastVt=visualmode()
  "echom "Visualmode: ".g:SmoothOperator#LastVt
  norm! m(om)

  " must leave visual mode so the markers get set
  exe "norm! \<esc>gv" 

  " get target's coordinates
  " target exists when hooking, not when invoking,
  " so we capture its geometry here
  let [sl, sc] = getpos("'<")[1:2]
  let [el, ec] = getpos("'>")[1:2]

  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 
  
  let g:SmoothOperator#StartingLine   = sl
  let g:SmoothOperator#EndingLine     = el
  let g:SmoothOperator#StartingColumn = sc
  let g:SmoothOperator#EndingColumn   = ec
  set opfunc=SmoothOperator#RunVisual
endfun

function! SmoothOperator#RunVisual(vt, ...)
  let vt=g:SmoothOperator#LastVt
  "echom "RunVisual ".vt
  " we must rebuild the selection
  let sl = g:SmoothOperator#StartingLine
  let el = g:SmoothOperator#EndingLine
  let sc = g:SmoothOperator#StartingColumn
  let ec = g:SmoothOperator#EndingColumn
  "echom "sl: ".sl."  sc: ".sc."  el: ".el."  ec: ".ec 
  if g:SmoothOperator#Repeating==0
    exe 'norm! \<esc>'
    if vt=='char' || vt=='v' 
      " our target is a text object or motion
      " visually select it
      call SmoothOperator#GoToLineCol(sl, sc) 
      norm! v
      call SmoothOperator#GoToLineCol(el, ec) 
    elseif vt=='line' || vt=='V'
      call SmoothOperator#GoToLine(sl) 
      norm! V
      call SmoothOperator#GoToLine(el) 
    elseif vt=='block' || vt=='<C-v>' || vt=='<c-v>'
      call SmoothOperator#GoToLineCol(sl, sc) 
      exe 'norm! \<c-v>'
      call SmoothOperator#GoToLineCol(el, ec) 
    endif
  else
    "echom "Repeating"
    " we are about to repeat a visual selection
    let lines = el - sl
    exe 'norm! \<esc>'
    exe 'norm! '.(vt=='v' || vt=='char'?'v':(vt=='V' || vt=='line'?'V':"\<C-v>"))
    call SmoothOperator#GoToLine(line(".")+lines)
    "echom "Desde linea: ".line(".")
    "echom "Hasta linea: ".(line(".")+lines)
    call SmoothOperator#MoveCols(ec-sc+1)
    "echom "Columnas: ".(ec-sc+1)
  endif
  " capture target's current text
  let old_yank=@a
  norm! "ay
  let g:SmoothOperator#LastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  "exe "norm! \<esc>"
  norm! gv
  let g:SmoothOperator#Repeating=1
  exe 'call '.g:SmoothOperator#Defined[g:SmoothOperator#LastRun] .'()'
endfun

function! SmoothOperator#GoToLineCol(l, c)
  call SmoothOperator#GoToLine(a:l)
  call SmoothOperator#GoToCol(a:c)
endfun

function! SmoothOperator#GoToLine(l)
  if line(".") > a:l
    exe 'norm! '.(line(".") - a:l).'k'
  elseif line(".") < a:l
    exe 'norm! '.(a:l - line(".")).'j'
  endi
endfun

function! SmoothOperator#MoveCols(n)
  "echom "a:n = ".a:n
  if(a:n > 1)
    exe 'norm! '.(a:n-1).'l'
  endif
endfun

function! SmoothOperator#GoToCol(c)
  norm! 0
  call SmoothOperator#MoveCols(a:c)
endfun

