
    " Relatively simple operators can be defines as mappings
    " they are called with "normal!", so we must escape special chars with \

    " Let's define "Paste before" and "Paste after" operator mappings
    call sade#Map("(p","\<esc>`<P")
    call sade#Map(")p","\<esc>`>p")

    " Let's define an operator function:
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
      let @w = "Inspect::view(".g:UserOperatorLastText.");"
      norm! o
      norm! "wp
      "norm! `<
    endfun


