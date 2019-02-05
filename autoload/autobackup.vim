if exists('s:save_cpo')| finish| endif
let s:save_cpo = &cpo| set cpo&vim
scriptencoding utf-8
"=============================================================================
let s:FILE_FORMAT = '%s/%s/%04s.%s'
let s:TMPEXT = '.0000.vim-autobackup'
let s:NUMDIR = 'pathnums'
function! s:make_bkdir() "{{{
  if mkdir(s:bkdir, 'p')
    let s:bkdir .= '/'
    return 0
  end
  echoerr 'g:autobackup_backup_dir could not be created: "'. g:autobackup_backup_dir. '"'
  return 1
endfunction
"}}}
function! s:make_cfgdir(dir) "{{{
  if mkdir(a:dir. '/'. s:NUMDIR, 'p')
    return 0
  end
  echoerr 'g:autobackup_config_dir could not be created: "'. g:autobackup_config_dir. '"'
  call delete(expand('<afile>:p'). s:TMPEXT)
  unlet! s:save_patchmode s:bkdir
  return 1
endfunction
"}}}
function! s:get_nextnum(bkfilename, num) "{{{
  let i = a:num
  while filereadable(printf(s:FILE_FORMAT, s:bkdir, a:bkfilename, i))
    let i += 1
  endwhile
  return i
endfunction
"}}}
function! s:mkdir(bkfilepath) "{{{
  let bkdirpath = fnamemodify(a:bkfilepath, ':h')
  if filereadable(bkdirpath)
    call delete(bkdirpath)
  endif
  if !isdirectory(bkdirpath)
    call mkdir(bkdirpath, 'p')
  endif
endfunction
"}}}
function! s:gen_bkpath(bkdir, bkfilename, num) "{{{
  " NOTE: # of file is prefix of filename due to keep file ext
  let bkpath = printf(s:FILE_FORMAT, a:bkdir, fnamemodify(a:bkfilename, ':h'), a:num, fnamemodify(a:bkfilename, ':t'))
  return bkpath
endfunction
"}}}
function! autobackup#pre() "{{{
  let path = expand('<afile>:p')
  if path == '' || &backupdir == '' || g:autobackup_backup_dir == '' || g:autobackup_config_dir == ''
    return
  end
  let s:bkdir = fnamemodify(g:autobackup_backup_dir, ':p')
  if fnamemodify(path, ':h'). '/' ==? s:bkdir || !isdirectory(s:bkdir) && s:make_bkdir()
    return
  end
  let s:save_patchmode = &patchmode
  if !(&patchmode == '' || filereadable(path. &patchmode)) && filereadable(path)
    call writefile(readfile(path), path. s:TMPEXT)
  else
    let &patchmode = s:TMPEXT
  end
endfunction
"}}}
function! autobackup#post() "{{{
  if !exists('s:save_patchmode')
    return
  end
  let &patchmode = s:save_patchmode
  let dir = fnamemodify(g:autobackup_config_dir, ':p')
  if !(isdirectory(dir) && isdirectory(dir. s:NUMDIR)) && s:make_cfgdir(dir)
    return
  end
  let basepath = expand('<afile>:p')
  let bkfilename = substitute(basepath, '[:\\]', '%', 'g')
  let numpath = dir. '/'. s:NUMDIR. '/'. bkfilename
  let num = (filereadable(numpath) ? get(readfile(numpath), 0, 0) : 0) + 1
  let bkpath = s:gen_bkpath(s:bkdir, bkfilename, num)
  call s:mkdir(bkpath)
  if filereadable(bkpath)
    let num = s:get_nextnum(bkfilename, num+1)
    let bkpath = s:gen_bkpath(s:bkdir, bkfilename, num)
  end
  " NOTE: move current dir based tmp file to tmp dir
  let tmppath = basepath. s:TMPEXT
  if filereadable(tmppath)
    call rename(tmppath, bkpath)
    call s:mkdir(numpath)
    call writefile([num], numpath)
    " NOTE: save # of file as cache
    if g:autobackup_backup_limit && num > g:autobackup_backup_limit
      call delete(s:gen_bkpath(s:bkdir, bkfilename, num - g:autobackup_backup_limit))
    end
  end
  unlet s:save_patchmode s:bkdir
endfunction
"}}}

"=============================================================================
"END "{{{1
let &cpo = s:save_cpo| unlet s:save_cpo
