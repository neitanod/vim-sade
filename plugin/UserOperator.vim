if exists("UserOperatorLoaded")
    finish
endif
let UserOperatorLoaded = 1

let g:UserOperatorDefined = {}

function! UserOperatorFunc(key, func)
  let g:UserOperatorDefined[a:key]=a:func
  exe "nnoremap ".a:key." :call UserOperatorHookNormal('".a:key."')<cr>g@"
  exe "vmap ".a:key." :call UserOperatorHookVisual('".a:key."')<cr>gvg@w"
endfun

function! UserOperatorHookNormal(key)
  let g:UserOperatorLastRun=a:key
  set opfunc=UserOperatorRun
endfun

function! UserOperatorHookVisual(key)
  let g:UserOperatorLastRun=a:key
  let g:UserOperatorLastMotion=''
  let g:UserOperatorRepeating=0
  vnoremap <Plug>UserOperatorRunMap :call UserOperatorRepeat(visualmode(), 1)<cr>
  vmap ,UOA <Plug>UserOperatorRunMap
  set opfunc=UserOperatorRepeat
endfun

function! UserOperatorRun(vt, ...)
  echom a:vt
  let g:UserOperatorLastMotion=@l
  let g:UserOperatorLastVt=a:vt
  let old_yank=@a
    " get target's coordinates
    let [sl, sc] = getpos(a:0 ? "'<" : "'[")[1:2]
    let [el, ec] = getpos(a:0 ? "'>" : "']")[1:2]

    let g:UserOperatorStartingLine   = sl
    let g:UserOperatorEndingLine     = el
    let g:UserOperatorStartingColumn = sc
    let g:UserOperatorEndingColumn   = ec

  if(a:vt=='char') 
    " our target is a text object or motion
    " visually select it
    exe 'norm! '.sl.'gg'
    norm! 0
    if(sc > 1)
      exe 'norm! '.(sc-1).'l'
    endif
    norm! v
    exe 'norm! '.el.'gg'
    norm! 0
    if(ec > 1)
      exe 'norm! '.(ec-1).'l'
    endif
  else
    " our target is a visual selection
    " reselect it
    norm! gv
  endif
  " capture target's current text
  norm! "ay
  let g:UserOperatorLastText=@a
  let @a=old_yank
  " reselect and call User's Operator
  norm! gv
  let g:UserOperatorRepeating=1
  exe 'call '.g:UserOperatorDefined[g:UserOperatorLastRun] .'()'
endfun

function! UserOperatorRepeat(vt, ...)
  if g:UserOperatorLastMotion == ''
    if g:UserOperatorRepeating==1
      " we are about to repeat a visual selection
      let lines = g:UserOperatorEndingLine - g:UserOperatorStartingLine
      let sc = g:UserOperatorStartingColumn
      let ec = g:UserOperatorEndingColumn
      norm! 0
      if(sc > 1)
        exe 'norm! '.(sc-1).'l'
      endif
      norm! v
      exe 'norm! '.(line(".")+lines).'gg'
      norm! 0
      if(ec > 1)
        exe 'norm! '.(ec-1).'l'
      endif
    endif
    exe 'norm! \<esc>gv'
    call UserOperatorRun(visualmode(), 1)
  else
    exe 'norm '.g:UserOperatorLastRun.g:UserOperatorLastMotion
  endif
endfun

function! InputChar()
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfun




" Let's try something:
call UserOperatorFunc('b','Test')

func! Test()
  " Target text is selected in visual mode now, 
  " you can yank it, delete it or do anything you want
  " including exiting to normal mode with:  exe 'norm! \<esc>'
  
  " Also, you have some predefined variables:
  "  g:UserOperatorLastText        A copy of the selected text
  "  g:UserOperatorStartingLine    Buffer line number of selection start
  "  g:UserOperatorEndingLine      Buffer line number of selection end 
  "  g:UserOperatorStartingColumn  Buffer column number of selection start
  "  g:UserOperatorEndingColumn    Buffer column number of selection end 
  
  " as usual, marks '< and '> are set at the start and end of the selection
  " so you can choose to position yourself at the beginning or end of the 
  " selection when you're done:    
  " go to the beginning:    norm! `<    
  " go to the end:          norm! `> 

  " (in this example we are going to paste into the line below as an argument
  " to a function call)"
  
  exe "norm! \<esc>"
  exe "norm! oInspect::view(".g:UserOperatorLastText.");\<esc>"
  norm! `>
endfun

