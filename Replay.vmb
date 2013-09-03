" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/ReplayPlugin.vim	[[[1
39
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
autoload/Replay.vim	[[[1
293
" Replay.vim - Replay your editing Session
" -------------------------------------------------------------
" Version: 0.5
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 14 Aug 2013 22:26:12 +0200
"
" Script: http://www.vim.org/scripts/script.php?script_id=3216
" Copyright:   (c) 2009, 2010, 2011, 2012, 2013  by Christian Brabandt
"              The VIM LICENSE applies to NrrwRgn.vim
"              (see |copyright|) except use "Replay.vim"
"              instead of "Vim".
"              No warranty, express or implied.
"    *** ***   Use At-Your-Own-Risk!   *** ***
" GetLatestVimScripts: 3216 6 :AutoInstall: Replay.vim
"
let s:dir=fnamemodify(expand("<sfile>"), ':p:h')
fun! <sid>WarningMsg(msg) "{{{1
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
	let s:replay_save   = (exists("g:replay_record")  ? g:replay_record   : 0 )
	let s:replay_record_param = {}
	if s:replay_save &&
	\ !(executable("ffmpeg") || executable("avconv")) &&
	\ !empty(expand("$DISPLAY"))
		" ffmpeg/avconv not available in $PATH or not running on X11 server
		let s:replay_save = 0
	else
		let s:replay_record_param['format'] = 'mkv'  " could be mkv, mpg, avi etc...
		let s:replay_record_param['exe']    = ( executable("avconv") ? 'avconv' : 'ffmpeg')
		let s:replay_record_param['log']    = "/tmp/replay.log"
		let s:replay_record_param['opts']    = "-f x11grab -s hd720 -show_region 1 -framerate 10 -y "
		let s:replay_record_param['file']    = "Vim_Recording"
	endif
	if s:replay_save && exists("g:replay_record_param")
		call extend(s:replay_record_param, g:replay_record_param, 'force')
	endif
endfun

fun! <sid>LastChange() "{{{1
	redir => a | silent! undolist |redir end
	let b=split(a, "\n")[-1]
	if b !~ '\d'
		return 0
	endif
	return split(b)[0]
endfun

fun! <sid>MaxTagLength() "{{{1
    let list=keys(b:replay_data)
    call map(list, 'len(v:val)')
    return max(list)
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

fun! <sid>Is(os) "{{{1
    if (a:os == "win")
        return has("win32") || has("win16") || has("win64")
    elseif (a:os == "mac")
        return has("mac") || has("macunix")
    elseif (a:os == "unix")
        return has("unix") || has("macunix")
    endif
endfu
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

fun! Replay#Replay(tag) "{{{1
	let _fen = &fen
	setl nofen " disable folding, so the changes can be better viewed.
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
	if !stop_change
		call <sid>WarningMsg("No undo data to replay available!")
		return
	endif

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
	" Record screen?
	if s:replay_save
		call Replay#ScreenCapture('on')
	endif
    while t < stop_change
        silent norm! g+
		norm! zz
		redraw!
        exe "sleep " .s:replay_speed . 'm'
		let t=changenr()
    endw
	if s:replay_save
		call Replay#ScreenCapture('off')
	endif
	let &l:fen = _fen
	call winrestview(curpos)
endfun

fun! Replay#ScreenCapture(on, ...) "{{{1
	if a:on ==? 'on'
		" Start Screen Recording
		if get(g:, 'replay_record', 0)
			let s:isset_replay_record=1
		else
			let s:isset_replay_record=0
			let g:replay_record=1
		endif
		call <sid>Init()
		if !s:replay_save
			call <sid>WarningMsg("No screen recording software available!")
			return
		endif

		let args = []
		if exists("a:1") && !empty(a:1)
			let args = matchlist(a:1, '^\s*\(-shell\)\?\s*\(\f\+\)\?')
			if !empty(args) && !empty(args[2])
				let s:replay_record_param['file'] = args[2]
			endif
		endif

		" Check needed pre-conditions
		if exists("v:windowid")      &&
		\ executable("xwininfo")     &&
		\ !empty(expand("$DISPLAY")) &&
		\ <sid>Is('unix')

			let geom = {}

			" get window coordinates
			let msg  = system("LC_ALL=C xwininfo -id ". v:windowid.
						\ '|grep "Absolute\|Width\|Height"')
			let geom["x"]      = matchstr(msg, '\s*Absolute upper-left X:\s\+\zs\d\+\ze\s*\n') + 0
			let geom["y"]      = matchstr(msg, '\s*Absolute upper-left Y:\s\+\zs\d\+\ze\s*\n') + 0
			let geom["width"]  = matchstr(msg, '\s*Width:\s\+\zs\d\+\ze\s*\n') + 0
			let geom["height"] = matchstr(msg, '\s*Height:\s\+\zs\d\+\ze\s*\n') + 0

			" record screen
			let cmd = printf('%s %s -i %s -vf crop=%d:%d:%d:%d %s/%s_%d.%s %s',
						\ s:replay_record_param['exe'],
						\ s:replay_record_param['opts'],
						\ (strlen($DISPLAY) == 2 ? $DISPLAY.'.0' : $DISPLAY),
						\ geom.width, geom.height, geom.x, geom.y,
						\ (filewritable(getcwd()) == 2 ? getcwd() : '$HOME'),
						\ s:replay_record_param['file'],
						\ strftime('%Y%m%d', localtime()),
						\ s:replay_record_param['format'],
						\ exists("s:replay_record_param['log']") ?
						\ '2> '. s:replay_record_param['log']  : '')
			let cmd = 'sh '. s:dir. '/screencapture.sh '. cmd
			if !exists("#ScreenCaptureQuit#VimLeave")
				" Stop screen recording when quitting vim
				augroup ScreenCaptureQuit
					au!
					au VimLeavePre * :call Replay#ScreenCapture('off')
				augroup end
			endif
			if !empty(args) && !empty(args[1])
				echom "Starting Shell, press <C-D> to return to this session"
				" give the user a possibility to read the message
				exe "sleep 2"
				let s:pid=system(cmd)
				exe ":sh"
			else
				let s:pid=system(cmd)
				" sleep shortly
				exe "sleep " .s:replay_speed . 'm'
			endif
		endif
	else
		" kill an existing screen recording session
		if exists("s:pid") && <sid>Is('unix')
			call system('kill '. s:pid)
		endif
		if exists("s:isset_replay_record") && s:isset_replay_record == 0
			unlet! g:replay_record
		endif
	endif
endfu

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

" Modeline "{{{1
" vim: ts=4 sts=4 fdm=marker com+=l\:\" fdl=0
doc/Replay.txt	[[[1
172
*Replay.txt*   A plugin to record and replay your editing sessions

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.5 Wed, 14 Aug 2013 22:26:12 +0200

Copyright: (c) 2009, 2010, 2011, 2012, 2013 by Christian Brabandt
           The VIM LICENSE applies to Replay.vim (see |copyright|)
           except use Replay.vim instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
1. Contents                                                  *ReplayPlugin*

        1.  Contents.....................................: |ReplayPlugin|
        2.  Replay Manual................................: |Replay-manual|
        3.  Replay Configuration.........................: |Replay-config|
        3.1   Replay Speed...............................: |Replay-speed|
        3.2   Replay Recording...........................: |Replay-record|
        4.  Replay Feedback..............................: |Replay-feedback|
        5.  Replay History...............................: |Replay-history|

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

                                                            *:ScreenCapture*
:ScreenCapture[!] [-shell] [filename]

                            If you have enabled screen capturing to video,
                            this command will start a screen capturing session
                            to video or stop it (if :ScreenCapture!) is used.
                            If you used the -shell argument, a new shell will
                            be started, else the current Vim session will be
                            recorded.
                            [filename] can optionally be given and
                            will be the name of the recorded session with the
                            date appended to it. See also |Replay-record| for
                            how to enable it.

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
3 Replay Configuration                                       *Replay-config*

3.1 Replay Speed                                              *Replay-speed*

You can configure the speed, with which to replay the changes, that have been
done. By default, Replay.vim pauses for 200ms after every change. If you want
to change this, set the variable g:replay_speed to a value in milliseconds in
your |.vimrc| >

    let g:replay_speed = 300
<
will replay your editing session with slower and pauses for 300ms after every
change.

3.2 Replay Recording                                        *Replay-record*

It is possible to record the replay using avconv/ffmeg. For this to work, you
need ffmpeg/avconv installed and vim needs to be run on an X11-Server. To
enable this, set the variable g:replay_record to 1 in your |.vimrc| like this: >


    let g:replay_record = 1
<
When the replay is started, it will be recorded using ffmpeg/avconv for
screencapturing and the result will be saved as Vim_Recording_YYYYMMDD.mkv (in
case you haven't specified an optional filename else it will be saved as
filename_YYYYMMDD.mkv) in either the current working directory (|:pwd|) if it
is writable or your $HOME directory. If you have used the optional -shell
argument, a new |:sh| will be started.

(Note, this currently works only on Unix/Linux and you need ffmpeg or avconv
in your $PATH for this to work)

==============================================================================
4. Replay Feedback                                         *Replay-feedback*

Feedback is always welcome. If you like the plugin, please rate it at the
vim-page:
http://www.vim.org/scripts/script.php?script_id=3216

You can also follow the development of the plugin at github:
http://github.com/chrisbra/Replay

Please don't hesitate to report any bugs to the maintainer, mentioned in the
third line of this document.

==============================================================================
5. Replay History                                          *Replay-history*

0.5: Aug 14, 2013 {{{2

- improvements for |:ScreenCapture| capture

0.4: Feb 27, 2013 {{{1

- disable folding
- enable to screenrecord the replay using ffmpeg/avconv
  (fixes https://github.com/chrisbra/Replay/issues/1,
  suggested by David Jacobs, thanks!)


0.3: Aug 27, 2010 {{{1

- Automatically stopp Recording for latest started Recording session
  (suggested by Salim Halim, thanks!)
- Changed recording of time to use localtime() instead of storing a string
- Better documentation for :ListRecordings
- ListRecordings now also displays the change number (so you can easily jump
  to a change using :undo)

0.2: Aug 24, 2010  {{{1

- Enabled |GLVS|
- small bugfixes
- changed default playback rate to 200ms

0.1: Aug 23, 2010 {{{1

- Initial upload
- development versions are available at the github repository
- put plugin on a public repository (http://github.com/chrisbra/NrrwRgn)

  }}}
==============================================================================
Modeline: {{{1
vim:tw=78:ts=8:ft=help:et:fdm=marker:fdl=0:norl
autoload/screencapture.sh	[[[1
7
#!/bin/sh
echo "Starting recording: `date -R`" >&2
echo "Parameters: $@" >&2
echo "==============================" >&2
$@ &
# return pid of screen capturing process so we can kill it later
echo $!
