" Replay.vim - Replay your editing Session
" -------------------------------------------------------------
" Version: 0.5
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 14 Aug 2013 22:26:12 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3216
" Copyright:   (c) 2009, 2010, 2011, 2012, 2013 by Christian Brabandt
"              The VIM LICENSE applies to NrrwRgn.vim 
"              (see |copyright|) except use "Replay.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3216 6 :AutoInstall: Replay.vim
"
" Init:
if exists("g:loaded_replay") || &cp || &ul == -1
  finish
endif

let g:loaded_replay      = 0.1
let s:cpo                = &cpo
set cpo&vim

" User_Command:
com! -bang -nargs=? -complete=custom,Replay#CompleteTags StartRecord :call Replay#TagState(<q-args>, !empty("<bang>"))
com! -complete=custom,Replay#CompleteTags -nargs=? StopRecord :call Replay#TagStopState(<q-args>)
com! -nargs=? -complete=custom,Replay#CompleteTags Replay :call Replay#Replay(<q-args>)
com! ListRecords :call Replay#ListStates()
com! -bang -nargs=* -complete=customlist,<sid>ScreenRecordUsage ScreenRecord :call Replay#ScreenCapture((empty("<bang>") ? "on" : "off"), <q-args>)

fu! <sid>ScreenRecordUsage(A,L,P)
	return ['[-shell] [filename] - Start Screen Capture [as filename] [and start a shell]', '! - Stop current recording session']
endfu

" Restore:
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdm=syntax
