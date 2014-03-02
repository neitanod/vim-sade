let g:UserOperatorDefined = {}
" high timeoutlen because if the mapping times out the recording does not end
" an it becomes a problem in current version of this plugin

function! UserOperatorFunc(key, func)
  let g:UserOperatorDefined[a:key]=a:func
  exe "nnoremap ".a:key." :call UserOperatorHookNormal('".a:key."','".a:func."')<cr>g@"
  exe "vnoremap ".a:key." :call UserOperatorHookVisual('".a:key."','".a:func."')<cr>"
endfun

function! UserOperatorHookNormal(key, func)
  let g:UserOperatorLastRun=a:key
  set opfunc=UserOperatorRun
endfun

function! UserOperatorHookVisual(key, func)
  let g:UserOperatorLastRun=a:key
  exe 'call UserOperatorRun(visualmode(), 1)'
endfun

function! UserOperatorRun(vt, ...)
  echom "Hook!"
  "exe 'norm! q'
  let g:UserOperatorLastMotion=@l
  "echomsg "a:vt=".a:vt." a:0=".a:0." LastMotion:".g:UserOperatorLastMotion
  let old_yank=@a
  if(a:vt=='char') 
    let [sl, sc] = getpos(a:0 ? "'<" : "'[")[1:2]
    let [el, ec] = getpos(a:0 ? "'>" : "']")[1:2]

    let g:UserOperatorStartingLine   = sl
    let g:UserOperatorEndingLine     = el
    let g:UserOperatorStartingColumn = sc
    let g:UserOperatorEndingColumn   = ec 
    
    "echomsg " Lines ".sl." a ".el." - Columns ".sc." a ".ec
    
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
    norm! gv
  endif
  norm! "aygv
  let g:UserOperatorLastText=@a
  let @a=old_yank
  "echomsg "Yanked: ".g:UserOperatorLastText
  "echomsg 'norm! :call '.g:UserOperatorDefined[g:UserOperatorLastRun] .'()<CR>'
  norm! gv
  exe 'call '.g:UserOperatorDefined[g:UserOperatorLastRun] .'()'
endfun

function! UserOperatorRepeat()
   echom 'norm '.a:key.g:UserOperatorLastMotion
   return
   if g:UserOperatorLastMotion == ''
     norm! gv
     exe 'norm '.g:UserOperatorLastRun
   else
     exe 'norm '.g:UserOperatorLastRun.g:UserOperatorLastMotion
   endif
endfun

function! InputChar()
  let c = getchar()
  return type(c) == type(0) ? nr2char(c) : c
endfun

call UserOperatorFunc('b','Test')


func! Test()
  " Target text is selected in visual mode now, 
  " you can yank it, delete it or do anything you want
  
  " Also, you have some predefined variables:
  "  g:UserOperatorLastText        A copy of the selected text
  "  g:UserOperatorStartingLine    Buffer line number of selection start
  "  g:UserOperatorEndingLine      Buffer line number of selection end 
  "  g:UserOperatorStartingColumn  Buffer column number of selection start
  "  g:UserOperatorEndingColumn    Buffer column number of selection end 
  "
  " as usual, marks '< and '> are set at the start and end of the selection
   
  " (in this example we are going to paste into the line below as an argument
  " to a PHP function call)"
  exe "norm! \<esc>"
  exe "norm! oInspect::view(".g:UserOperatorLastText.");"
endfun



"<?php echo $a; ?>




"Inspect("<?php echo $a; ?>);

nnoremap <F12> :w<CR>:so %<CR> 
