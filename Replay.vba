" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/ReplayPlugin.vim	[[[1
34
" Replay.vim - Replay your editing Session
" -------------------------------------------------------------
" Version: 0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 27 Aug 2010 14:18:31 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"              The VIM LICENSE applies to NrrwRgn.vim 
"              (see |copyright|) except use "Replay.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3216 4 :AutoInstall: Replay.vim
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

" Restore:
let &cpo=s:cpo
unlet s:cpo
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdm=syntax
autoload/Replay.vim	[[[1
166
" Replay.vim - Replay your editing Session
" -------------------------------------------------------------
" Version: 0.3
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 27 Aug 2010 14:18:31 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=
" Copyright:   (c) 2009, 2010 by Christian Brabandt
"              The VIM LICENSE applies to NrrwRgn.vim 
"              (see |copyright|) except use "Replay.vim" 
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3216 4 :AutoInstall: Replay.vim
"
fun! <sid>WarningMsg(msg)"{{{1
        echohl WarningMsg
        let msg = "ReplayPlugin: " . a:msg
        if exists(":unsilent") == 2
                unsilent echomsg msg
        else
                echomsg msg
        endif
        echohl Normal
        let v:errmsg = msg
endfun

fun! <sid>Init() "{{{1
    if !exists("b:replay_data")
        let b:replay_data={}
		let b:replay_data.Default={}
		let b:replay_data.Default.start=0
		let b:replay_data.Default.start_time=localtime()
    endif
    " Customization
    let s:replay_speed  = (exists("g:replay_speed")   ? g:replay_speed    : 200)
endfun 

fun! Replay#Replay(tag) "{{{1
    call <sid>Init()
	if empty(a:tag)
		let tag='Default'
	else
		let tag=a:tag
	endif
	if !exists("b:replay_data.".tag)
		call <sid>WarningMsg("Tag " . tag . " does not exist!")
		return
	endif
	let curpos=winsaveview()
    let undo_change=get(b:replay_data, tag)
    let stop_change=<sid>LastChange()

    if undo_change.start==0
        undo 1
        norm! g-
    else
        if exists("undo_change.stop")
            let stop_change=undo_change.stop
        endif
        exe "undo " undo_change.start
    endif
    let t=changenr()
    while t < stop_change
        silent norm! g+
		norm! zz
		redraw!
        exe "sleep " .s:replay_speed . 'm'
		let t=changenr()
    endw
	call winrestview(curpos)
endfun

fun! <sid>LastChange() "{{{1
	redir => a | silent! undolist |redir end
	let b=split(a, "\n")[-1]
	return split(b)[0]
endfun

fun! Replay#TagState(tag, bang) "{{{1
	call <sid>Init()
    let tag=(empty(a:tag) ? 'Default' : a:tag)
    if exists("b:replay_data.".tag) && !a:bang
        call <sid>WarningMsg("Tag " . tag . " already exists!")
        return
    else
		let b:replay_data[tag] = {}
        let b:replay_data[tag].start = changenr()
        let b:replay_data[tag].start_time = localtime()
    endif
endfun

fun! Replay#TagStopState(tag) "{{{1
	call <sid>Init()
    "let tag=(empty(a:tag) ? 'Default' : a:tag)
	let tag=(empty(a:tag) ? <sid>LastStartedRecording() : a:tag)
    if !exists("b:replay_data.".tag) "&& tag != 'Default'
        call <sid>WarningMsg("Tag " . tag . " not found!")
        return
    else
		let change=changenr()
		if tag == 'Default'
			let b:replay_data[tag] = {}
		endif
		" If stop is before start, swap both changes
		if !exists("b:replay_data[tag].start")
			let b:replay_data[tag].start = 0
			let b:replay_data[tag].stop = change
			let b:replay_data[tag].stop_time = localtime()
		elseif b:replay_data[tag].start > change
			let b:replay_data[tag].stop = b:replay_data[tag].start
			let b:replay_data[tag].start = change
			let b:replay_data[tag].stop_time = localtime()
		else
			let b:replay_data[tag].stop = change
			let b:replay_data[tag].stop_time = localtime()
		endif
    endif
	call <sid>WarningMsg("Stopped Recording of: " . tag . " tag")
endfun

fun! <sid>MaxTagLength() "{{{1
    let list=keys(b:replay_data)
    call map(list, 'len(v:val)')
    return max(list)
endfun

fun! Replay#ListStates() "{{{1
    call <sid>Init()
    echohl Title
    let len=<sid>MaxTagLength()
	if len==0
		let len=3
	endif
    echo printf("%*.*s\t%s\t\t%s\t\t%s\t%s\n",len,len,"Tag", "Starttime", "Start", "Stoptime", "Stop")
    echohl Normal
	echo printf("%s", '===================================================================================')
    for key in keys(b:replay_data)
        echo printf("%*.*s\t%s\t%s\t%s\t%s", len,len, key,
					\(exists("b:replay_data[key].start_time") ? strftime("%d.%m.%Y %H:%M:%S", b:replay_data[key].start_time) : repeat('-',19)),
					\(exists("b:replay_data[key].start")      ? b:replay_data[key].start                                     : ' '),
					\(exists("b:replay_data[key].stop_time")  ? strftime("%d.%m.%Y %H:%M:%S", b:replay_data[key].stop_time)  : repeat('-',19)),
					\(exists("b:replay_data[key].stop")       ? b:replay_data[key].stop                                      : ' '))
    endfor
endfun

fun! Replay#CompleteTags(A,L,P) "{{{1
	 cal <sid>Init()
	 return join(sort(keys(b:replay_data)),"\n")
endfun

fun! <sid>LastStartedRecording() "{{{1
	let a=copy(b:replay_data)
	call filter(a, '!exists("v:val.stop")')
	let key=''
	let time=0
	for item in keys(a)
		if a[item].start_time > time
		   let time=a[item].start_time
		   let key = item
		endif
	endfor
	return key
endfun
" Modeline "{{{1
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
doc/Replay.txt	[[[1
119
*Replay.txt*   A plugin to record and replay your editing sessions

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.3 Fri, 27 Aug 2010 14:18:31 +0200

Copyright: (c) 2009, 2010 by Christian Brabandt
           The VIM LICENSE applies to Replay.vim (see |copyright|)
           except use Replay.vim instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                  *ReplayPlugin*

        1.  Contents.....................................: |ReplayPlugin|
        2.  Replay Manual................................: |Replay-manual|
        2.1   Replay Configuration.......................: |Replay-config|
        3.  Replay Feedback..............................: |Replay-feedback|
        4.  Replay History...............................: |Replay-history|

==============================================================================
2. Replay Manual                                            *Replay-manual*

Functionality

This plugin allows you to record and replay your changes that have been done
to a buffer.


                                                            *:StartRecord*
:StartRecord[!] [Tag]       This will start a new record session, that will be
                            called Tag. If [Tag] is not given, use the
                            "Default" tag name. If the tag already exists, an
                            error is given and it will be aborted. Use ! to
                            overwrite an existing tag name.
                            You can use <Tab> to complete the available Tag
                            names

                                                            *:StopRecord*
:StopRecord[!] [Tag]        Recording Session for the Tag will stop at this
                            change.
                            If you don't enter a Tag name, the last started
                            recording session will stop.
                            You can use <Tab> to complete the available Tag
                            names

                                                                    *:Replay*
:Replay [Tag]               Start Replaying your Session, that is identified
                            by the tag Tag. If Tag is not given, use the
                            default tag "Default"
                            You can use <Tab> to complete the available Tag
                            names

                                                            *:ListRecords*
:ListRecords                Show which tags are available. This presents a
                            little table that looks like this:

    Tag Starttime               Start           Stoptime        Stop~
=====================================================================
   abcd 27.08.2010 14:12:01     164     27.08.2010 14:12:11     168
Default 27.08.2010 14:09:26     0       -------------------

That means one Recording called "abcd" was started in the undo-tree with the
change number 164. (You can jump back to that change using :undo 164, see also
|:undo|.) Recording time for that tag started on August, 27, 2010 at 14:12:01
o'clock and recording will stop at change number 168 which was at 14:12:11
o'clock. Please bear in mind, that the starting time for the Default-Tag can't
exactly be given, but is the first time, any of the above commands was called.

==============================================================================
2.1 Replay Configuration                                    *Replay-config*

You can configure the speed, with which to replay the changes, that have been
done. By default, Replay.vim pauses for 200ms after every change. If you want
to change this, set the variable g:replay_speed to a value in milliseconds in
your |.vimrc| >

    let g:replay_speed = 300
<
will replay your editing session with slower and pauses for 300ms after every
change.
==============================================================================
3. Replay Feedback                                         *Replay-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3216

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Replay

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
4. Replay History                                          *Replay-history*

0.3: Aug 27, 2010
- Automatically stopp Recording for latest started Recording session
  (suggested by Salim Halim, thanks!)
- Changed recording of time to use localtime() instead of storing a string
- Better documentation for :ListRecordings
- ListRecordings now also displays the change number (so you can easily jump
  to a change using :undo)

0.2: Aug 24, 2010
- Enabled |GLVS|
- small bugfixes
- changed default playback rate to 200ms

0.1: Aug 23, 2010       

- Initial upload
- development versions are available at the github repository
- put plugin on a public repository (http://github.com/chrisbra/NrrwRgn)

==============================================================================
Modeline:
vim:tw=78:ts=8:ft=help:et
