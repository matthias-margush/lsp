vim9script

# Functions related to displaying hover symbol information.

import './util.vim'
import './options.vim' as opt

# process the 'textDocument/hover' reply from the LSP server
# Result: Hover | null
export def HoverReply(lspserver: dict<any>, hoverResult: any): void
  if hoverResult->empty()
    return
  endif

  var hoverText: list<string>
  var hoverKind: string

  if hoverResult.contents->type() == v:t_dict
    if hoverResult.contents->has_key('kind')
      # MarkupContent
      if hoverResult.contents.kind == 'plaintext'
        hoverText = hoverResult.contents.value->split("\n")
        hoverKind = 'text'
      elseif hoverResult.contents.kind == 'markdown'
        hoverText = hoverResult.contents.value->split("\n")
        hoverKind = 'markdown'
      else
        util.ErrMsg($'Error: Unsupported hover contents type ({hoverResult.contents.kind})')
        return
      endif
    elseif hoverResult.contents->has_key('value')
      # MarkedString
      hoverText = hoverResult.contents.value->split("\n")
    else
      util.ErrMsg($'Error: Unsupported hover contents ({hoverResult.contents})')
      return
    endif
  elseif hoverResult.contents->type() == v:t_list
    # interface MarkedString[]
    for e in hoverResult.contents
      if e->type() == v:t_string
        hoverText->extend(e->split("\n"))
      else
        hoverText->extend(e.value->split("\n"))
      endif
    endfor
  elseif hoverResult.contents->type() == v:t_string
    if hoverResult.contents->empty()
      return
    endif
    hoverText->extend(hoverResult.contents->split("\n"))
  else
    util.ErrMsg($'Error: Unsupported hover contents ({hoverResult.contents})')
    return
  endif

  if opt.lspOptions.hoverInPreview
    silent! pedit LspHoverReply
    wincmd P
    setlocal buftype=nofile
    setlocal bufhidden=delete
    exe $'setlocal ft={hoverKind}'
    bufnr()->deletebufline(1, '$')
    append(0, hoverText)
    cursor(1, 1)
    wincmd p
  else
    hoverText->popup_atcursor({moved: 'word'})
  endif
enddef

# vim: tabstop=8 shiftwidth=2 softtabstop=2
