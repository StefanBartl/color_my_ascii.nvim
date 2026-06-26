---@module 'color_my_ascii.languages.vim'
--- Vimscript/VimL language keyword definitions for ASCII art highlighting

---@type ColorMyAscii.KeywordGroup
return {
  words = {
    -- Control flow
    'if', 'else', 'elseif', 'endif',
    'for', 'in', 'endfor',
    'while', 'endwhile',
    'do', 'break', 'continue', 'return',
    'try', 'catch', 'finally', 'endtry', 'throw',
    -- Declarations & commands
    'let', 'const', 'unlet',
    'set', 'setlocal', 'setglobal',
    'call', 'execute', 'eval',
    'echo', 'echom', 'echon', 'echohl', 'echoerr',
    'silent', 'silentm', 'unsilent',
    'normal', 'normal!',
    'function', 'endfunction', 'abort', 'closure',
    'command', 'delcommand',
    'autocmd', 'augroup', 'doautocmd',
    'highlight', 'syntax',
    'map', 'noremap', 'unmap',
    'nmap', 'nnoremap', 'nnoremenu',
    'vmap', 'vnoremap', 'xmap', 'xnoremap',
    'imap', 'inoremap',
    'omap', 'onoremap',
    'tmap', 'tnoremap',
    'cmap', 'cnoremap',
    'source', 'runtime', 'finish',
    'sign', 'wincmd', 'tabdo', 'bufdo', 'argdo',
    -- Values / literals
    'v:true', 'v:false', 'v:null', 'v:none',
    'has', 'exists',
    -- Common built-in functions
    'expand', 'fnamemodify', 'resolve',
    'shellescape', 'fnameescape',
    'system', 'systemlist',
    'bufnr', 'bufexists', 'bufloaded', 'buflisted',
    'winnr', 'winbufnr', 'win_getid', 'win_gotoid',
    'tabpagenr', 'tabpagebuflist',
    'line', 'col', 'virtcol', 'indent',
    'getline', 'setline', 'append', 'delete',
    'getpos', 'setpos', 'getcurpos', 'cursor',
    'search', 'searchpos', 'match', 'matchstr', 'matchend',
    'substitute', 'submatch',
    'split', 'join', 'trim', 'tolower', 'toupper',
    'strlen', 'strchars', 'strdisplaywidth', 'strpart', 'strcharpart',
    'printf', 'string', 'nr2char', 'char2nr',
    'len', 'empty', 'type',
    'get', 'has_key', 'keys', 'values', 'items',
    'filter', 'map', 'sort', 'reverse',
    'copy', 'deepcopy', 'extend', 'remove', 'insert', 'index', 'count',
    'abs', 'ceil', 'floor', 'float2nr', 'pow', 'sqrt', 'round',
    'max', 'min', 'range',
    'readfile', 'writefile', 'glob', 'globpath', 'isdirectory', 'filereadable',
    'input', 'inputlist', 'confirm',
    'feedkeys', 'getchar', 'getcharstr',
    'mode', 'visualmode',
    'reg_executing', 'getreg', 'setreg',
    'synID', 'synIDattr', 'synstack', 'hlID',
    'sign_define', 'sign_place', 'sign_unplace',
    'luaeval', 'json_encode', 'json_decode',
  },

  -- Keywords unique to Vimscript
  unique_words = {
    'endif', 'endfor', 'endwhile', 'endfunction', 'endtry',
    'augroup', 'doautocmd',
    'echom', 'echoerr', 'echohl',
    'nnoremap', 'vnoremap', 'inoremap', 'xnoremap', 'onoremap', 'tnoremap', 'cnoremap',
    'setlocal', 'setglobal',
    'unlet', 'delcommand',
    'luaeval', 'feedkeys',
  },

  hl = 'Statement',
}
