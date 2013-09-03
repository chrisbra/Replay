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
			if s:replay_record_param['file'] =~ '.gif$' && executable('byzanz-record')
				" try recording using byzanz
				let cmd = printf('byzanz-record --display=%s --height=%s --width=%s --x=%s --y=%s %s %s',
						\ (strlen($DISPLAY) == 2 ? $DISPLAY.'.0' : $DISPLAY),
						\ geom.height, geom.width, geom.x, geom.y,
						\ s:replay_record_param['file'],
						\ exists("s:replay_record_param['log']") ?
						\ '2> '. s:replay_record_param['log']  : '')
			else
				" fall back using ffmpeg/avconv
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
			endif
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
