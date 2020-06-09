set nocompatible              " be iMproved, required. 避免兼容vi造成很多功能缺失
filetype plugin indent on
"set omnifunc=syntaxcomplete#Complete 

" vim-plug settings. -------------------------------------------{{{
call plug#begin('~/.vim/plugged')
Plug 'SirVer/ultisnips'
Plug 'honza/vim-snippets'
Plug 'scrooloose/nerdcommenter'
Plug 'maralla/completor.vim', {'for': ['python']}
Plug 'w0rp/ale'
Plug 'davidhalter/jedi-vim', {'for': 'python'}
"Plug 'brookhong/cscope.vim'
Plug 'vim-scripts/autoload_cscope.vim'
Plug 'godlygeek/tabular'
Plug 'plasticboy/vim-markdown', {'for': 'markdown'}
Plug 'vim-scripts/taglist.vim'
Plug 'vim-scripts/winmanager'
Plug 'vim-scripts/ifdef-highlighting', {'for': ['c', 'cpp']}
Plug 'psliwka/vim-smoothie'
Plug 'JamshedVesuna/vim-markdown-preview', {'for': 'markdown'}
Plug 'lifepillar/pgsql.vim', {'for': 'sql'}
Plug 'neoclide/coc.nvim', {'branch': 'release', 'for': ['c', 'cpp', 'html', 'java', 'javascript', 'css', 'json']}
Plug 'gko/vim-coloresque'
"color themes below
Plug 'morhetz/gruvbox'
Plug 'lifepillar/vim-gruvbox8'
Plug 'NLKNguyen/papercolor-theme'
Plug 'KeitaNakamura/neodark.vim'
Plug 'sergio-ivanuzzo/optcmd'
call plug#end()
"----------------------}}}

" Vimscript file settings ---------------------- {{{
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
"---------------}}}

" vim settings. -------------------------------------------- {{{
set nu
set hlsearch
"set laststatus=2
set autochdir
nnoremap <SPACE> <Nop>
let mapleader = "\<space>"
nnoremap <silent><expr> <F2> (&hls && v:hlsearch ? ':nohls' : ':set hls')."\n"
set dictionary+=/usr/share/dict/words
set dictionary+=~/.vim/dict.txt
"zR open all, zr open level, zM close all, zm close level
set foldmethod=indent
"set foldmethod=syntax
set foldlevelstart=9
"keep folds on save --
augroup remember_folds
  autocmd!
  autocmd BufWinLeave * mkview
  autocmd BufWinEnter * silent! loadview
augroup END
"set completeopt=menu,menuone,preview,noselect,noinsert
set completeopt-=preview
"set cul " highlight current line
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
autocmd FileType javascript setlocal shiftwidth=4 tabstop=4 softtabstop=0 expandtab
autocmd FileType c setlocal shiftwidth=4 tabstop=4 softtabstop=0 noexpandtab

"----------}}}

"vim run file actions ----------{{{
function! GetConfirmChoicesString(choices)
" TODO: 适应选项数量大于10个的情况，适应ascii码从49到126总共78个选项,
" 增加正则表达式应用于不同文件
        let id=1
        let result=""
        for choice in a:choices
                let result.="&".id.choice."\n"
                let id+=1
        endfor
        return result
endfunction

function! SaveAndExe(cmd)
        if &modified
                execute "w"
        endif
        execute "!".a:cmd
endfunction

function! RunDefaultCmd()
        let defaultcmd={'python':'python3 %', 'javascript':'node %', 'sh':'sh %', 'html':'firefox %', 'c':'gcc % -O3 && ./a.out','cpp':'g++ % -O3 && ./a.out'}
        if has_key(defaultcmd, &ft)
                call SaveAndExe(defaultcmd[&ft])
                return 1
        else
                return 0
        endif

endfunction

function! RunProject()
        let level=5
        let runcmdfile=".run"
        while(level>0)
                if filereadable(expand('%:p:h')."/".runcmdfile)
                        break
                endif
                let runcmdfile="../".runcmdfile
                let level-=1
        endwhile
        " 找不到run文件
        if level<=0
                if !RunDefaultCmd()
                echohl WarningMsg | echo "readable .run file not found!" | echohl None
                endif
                return
        endif
        " 找到了run文件
        let runcmdfilefullpath=expand('%:p:h')."/".runcmdfile
        let content=readfile(runcmdfilefullpath)
        " 去掉注释和空行,注释以#开头,不支持去掉放在命令后面的注释
        let file_pattern_match=0
        let commands=[]
        for line in content
                if (line =~# "^\\s*#[^!]") || (line =~# "^\\s*$")
                        continue
                elseif line =~# "^\\s*#!"
                        if file_pattern_match==1
                                break
                        endif
                        let file_pattern = trim(trim(line)[2:])
                        if expand("%") =~# file_pattern
                               let file_pattern_match=1
                        endif
                elseif file_pattern_match==1
                        call add(commands, line)
                else
                        continue
                endif
        endfor
        if len(commands)==0 && file_pattern_match==0
                "没有指明匹配规则
                call RunDefaultCmd()
        elseif len(commands)==0 && file_pattern_match==1
                "指明了匹配规则，但命令列表为空
                echo "commandlist is blank"
        endif
        if len(commands)==1
                call SaveAndExe(commands[0])
        else
                let choices=GetConfirmChoicesString(commands)
                let choice=confirm("Which command to run?", choices, 0)
                if choice==0
                        return
                else
                        call SaveAndExe(commands[choice-1])
                endif
        endif
endfunction
" nmap <F5> <esc>:w<cr>:!python3 %<cr>
nmap <F5> :call RunProject()<CR>
"------------}}}

" Mark settings. (this is a plugin)------------------{{{
nmap ,m <Plug>MarkSet
vmap ,m <Plug>MarkSet
nmap ,r <Plug>MarkRegex
vmap ,r <Plug>MarkRegex
nmap ,n <Plug>MarkClear
"--------------}}}

" jedi-vim settings. -------------------------------------------- {{{
"jedi-vim: show doc K, completion, goto definition \d,goto assignment \g show usages \n, rename var \r--
if &ft=='python'
let g:jedi#completions_enabled = 0
let g:jedi#popup_select_first = 1
"let g:jedi#show_call_signatures = 2
endif
"----------------}}}

" ale settings. ale: lint fix autoformat ---------------------- {{{
" see git:ale/ale_linters ----{{{
let g:ale_linters = {
\   'c': ['clangd'],
\   'python': ['flake8'],
\   'html': ['fecs','tidy'],
\   'css': ['fecs'],
\   'javascript': ['fecs'],
\   'sql': ['sqlint'],
\   'json': ['jsonlint'],
\   'sh': ['shellcheck'],
\   'java': ['javac'],
\   'gitcommit': ['gitlint'],
\   'php': ['phpcs'],
\   'qml': ['qmllint'],
\   'scala': ['fsc'],
\   'xml': ['xmllint'],
\   'awk': ['gawk'],
\   'markdown': ['textlint'],
\   'cmake': ['cmakelint'],
\   'make': ['checkmake'],
\}
"---}}}

" see ale/doc/ale-supported-languages-and-tools.txt ---{{{
let g:ale_fixers = {
\   'c': ['clang-format'],
\   'cpp': ['clang-format'],
\   'python': ['isort','autopep8'],
\   'html': ['fecs'],
\   'css': ['fecs'],
\   'javascript': ['fecs'],
\   'sql': ['pgformatter','sqlfmt','sqlformat'],
\   'json': ['jq'],
\   'sh': ['shfmt'],
\   'java': ['uncrustify'],
\   'php': ['phpcbf'],
\   'xml': ['xmllint'],
\   'cmake': ['cmakelint'],
\   'markdown': ['textlint'],
\}
"----}}}

nmap <silent> <C-k> <Plug>(ale_previous_wrap)
nmap <silent> <C-j> <Plug>(ale_next_wrap)
nmap <F8> <Plug>(ale_fix)
let g:ale_completion_enabled=0
" format style configuration of linux kernel code: torvalds/linux/master/.clang-format
let g:ale_c_clangformat_options='-style=file'
nn <silent> <C-d> :ALEGoToDefinition<cr>
nn <silent> <M-r> :ALEFindReferences<cr>
nn <silent> <M-a> :ALESymbolSearch<cr>
nn <silent> <M-h> :ALEHover<cr>
"---------------------------------------}}}

" completor settings. ----------------------- --------------------- {{{
let g:completor_python_binary = '/usr/bin/python3'
let g:completor_clang_binary = '/usr/bin/clang'
let g:completor_complete_options='menu,menuone,noinsert'
"noselect,preview
" noremap <silent> <leader>d :call completor#do('definition')<CR>
" noremap <silent> <leader>c :call completor#do('doc')<CR>
" noremap <silent> <leader>f :call completor#do('format')<CR>
" noremap <silent> <leader>s :call completor#do('hover')<CR>
"--------------------------}}}

" taglist settings. -------------------------------------------- {{{
let Tlist_Ctags_Cmd='ctags' "放在环境变量里，可直接执行
let Tlist_Use_Right_Window=0 "窗口显示在右边，0则在左边
let Tlist_Show_One_File=0 "让taglist可以同时展示buffer里所有文件的函数列表,使用:TlistAddFiles /myprojectpath/*/*.c添加
let Tlist_File_Fold_Auto_Close=1 "非当前文件，函数列表折叠隐藏
let Tlist_Exit_OnlyWindow=1 "当taglist是最后一个分割窗口时，自动推出vim
"是否一直处理tags.1:处理;0:不处理
let Tlist_Process_File_Always=1 "实时更新tags
let Tlist_Inc_Winwidth=0
"---------------}}}

" windowmanager settings. -------------------------------------------- {{{
let g:winManagerWindowLayout='FileExplorer|TagList'
nmap <C-w>m :WMToggle<cr>
"---------------}}}

"autoload-cscope settings.-------------------------------------{{{
"-- autoload_cscope has the following keymaps"
" <C-\>s :cs find s 同时按住ctrl和\，然后松开按s
" refer :help cscope_find for more
"-------------}}}

" Highlight debug blocks in c/cpp code. -------------------------------------------- {{{
" move cursor to the macro and type ,a
" see https://vim.fandom.com/wiki/Highlight_debug_blocks_in_programs
syn region MySkip contained start="^\s*#\s*\(if\>\|ifdef\>\|ifndef\>\)" skip="\\$" end="^\s*#\s*endif\>" contains=MySkip

let g:CommentDefines = ""

hi link MyCommentOut2 MyCommentOut
hi link MySkip MyCommentOut
hi link MyCommentOut Comment

map <silent> ,a :call AddCommentDefine()<CR>
map <silent> ,x :call ClearCommentDefine()<CR>

function! AddCommentDefine()
  let g:CommentDefines = "\\(" . expand("<cword>") . "\\)"
  syn clear MyCommentOut
  syn clear MyCommentOut2
  exe 'syn region MyCommentOut start="^\s*#\s*ifdef\s\+' . g:CommentDefines . '\>" end=".\|$" contains=MyCommentOut2'
  exe 'syn region MyCommentOut2 contained start="' . g:CommentDefines . '" end="^\s*#\s*\(endif\>\|else\>\|elif\>\)" contains=MySkip'
endfunction

function! ClearCommentDefine()
  let g:ClearCommentDefine = ""
  syn clear MyCommentOut
  syn clear MyCommentOut2
endfunction
"-------------}}}

" vim-markdown-preview settings. ---------------------------{{{
" using grip for GitHub flavoured markdown
let vim_markdown_preview_github=1
"-----------------}}}

" nerdcommenter settings. -------------------------------------------- {{{
nmap <C-_>   <Plug>NERDCommenterToggle
vmap <C-_>   <Plug>NERDCommenterToggle<CR>gv
" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Use compact syntax for prettified multi-line comments
let g:NERDCompactSexyComs = 1

" Align line-wise comment delimiters flush left instead of following code indentation
let g:NERDDefaultAlign = 'left'

" Set a language to use its alternate delimiters by default
let g:NERDAltDelims_java = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

" Allow commenting and inverting empty lines (useful when commenting a region)
let g:NERDCommentEmptyLines = 1

" Enable trimming of trailing whitespace when uncommenting
let g:NERDTrimTrailingWhitespace = 1

" Enable NERDCommenterToggle to check all selected lines is commented or not
let g:NERDToggleCheckAllLines = 1
"-----------}}}

"coc settings.--------------------------------------------------------{{{
"coc static display settings-----------{{{
" if hidden is not set, TextEdit might fail.
set hidden

" Some servers have issues with backup files, see #649
set nobackup
set nowritebackup

"Better display for messages
set cmdheight=2

" You will have bad experience for diagnostic messages when it's default 4000.
set updatetime=300

" don't give |ins-completion-menu| messages.
set shortmess+=c
" Add status line support, for integration with other plugin, checkout `:h coc-status`
set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
"-----------}}}
"coc action settings--------------{{{
" Use `[g` and `]g` to navigate diagnostics
" nmap <silent> [g <Plug>(coc-diagnostic-prev)
" nmap <silent> ]g <Plug>(coc-diagnostic-next)

" Remap keys for gotos
nmap <silent> <leader>d <Plug>(coc-definition)
nmap <silent> <leader>t <Plug>(coc-type-definition)
nmap <silent> <leader>i <Plug>(coc-implementation)
nmap <silent> <leader>g <Plug>(coc-references)

function! s:show_documentation()
  if (index(['vim','help'], &filetype) >= 0)
    execute 'h '.expand('<cword>')
  else
    call CocAction('doHover')
  endif
endfunction

augroup coc_mappings
    autocmd!
    autocmd FileType c,cpp,javascript,html,css,json nnoremap <silent> K :call <SID>show_documentation()<CR>
    autocmd FileType c,cpp,javascript,html,css,json nmap <buffer> <silent> <leader>h :call CocActionAsync('highlight')<CR>
augroup END

" Highlight symbol under cursor on CursorHold
"autocmd CursorHold * silent call CocActionAsync('highlight')

" Remap for rename current word
nmap <leader>r <Plug>(coc-rename)

" Remap for format selected region
xmap <leader>f  <Plug>(coc-format-selected)
nmap <leader>f  <Plug>(coc-format-selected)

augroup mygroup
  autocmd!
  " Setup formatexpr specified filetype(s).
  autocmd FileType typescript,json setl formatexpr=CocAction('formatSelected')
  " Update signature help on jump placeholder
  autocmd User CocJumpPlaceholder call CocActionAsync('showSignatureHelp')
augroup end

" Remap for do codeAction of selected region, ex: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)
nmap <leader>a  <Plug>(coc-codeaction-selected)

" Remap for do codeAction of current line
nmap <leader>ac  <Plug>(coc-codeaction)
" Fix autofix problem of current line
nmap <leader>qf  <Plug>(coc-fix-current)

" Create mappings for function text object, requires document symbols feature of languageserver.
xmap if <Plug>(coc-funcobj-i)
xmap af <Plug>(coc-funcobj-a)
omap if <Plug>(coc-funcobj-i)
omap af <Plug>(coc-funcobj-a)

" Use <TAB> for select selections ranges, needs server support, like: coc-tsserver, coc-python
nmap <silent> <TAB> <Plug>(coc-range-select)
xmap <silent> <TAB> <Plug>(coc-range-select)

" Use `:Format` to format current buffer
"command! -nargs=0 Format :call CocAction('format')

" Use `:Fold` to fold current buffer
"command! -nargs=? Fold :call     CocAction('fold', <f-args>)

" use `:OR` for organize import of current buffer
command! -nargs=0 OR   :call     CocAction('runCommand', 'editor.action.organizeImport')
"----------}}}
" Using CocList----------{{{
" Show all diagnostics
nnoremap <silent> ,a  :<C-u>CocList diagnostics<cr>
" Manage extensions
nnoremap <silent> ,e  :<C-u>CocList extensions<cr>
" Show commands
nnoremap <silent> <space>c  :<C-u>CocList commands<cr>
" Find symbol of current document
nnoremap <silent> <space>o  :<C-u>CocList outline<cr>
" Search workspace symbols
nnoremap <silent> <space>s  :<C-u>CocList -I symbols<cr>
" Do default action for next item.
nnoremap <silent> <space>j  :<C-u>CocNext<CR>
" Do default action for previous item.
nnoremap <silent> <space>k  :<C-u>CocPrev<CR>
" Resume latest coc list
nnoremap <silent> <space>p  :<C-u>CocListResume<CR>
"------------}}}
" popup scroll--------------------------{{{
  function FindCursorPopUp()
     let radius = get(a:000, 0, 2)
     let srow = screenrow()
     let scol = screencol()
     " it's necessary to test entire rect, as some popup might be quite small
     for r in range(srow - radius, srow + radius)
       for c in range(scol - radius, scol + radius)
         let winid = popup_locate(r, c)
         if winid != 0
           return winid
         endif
       endfor
     endfor

     return 0
   endfunction

   function ScrollPopUp(down)
     let winid = FindCursorPopUp()
     if winid == 0
       return 0
     endif

     let pp = popup_getpos(winid)
     call popup_setoptions( winid,
           \ {'firstline' : pp.firstline + ( a:down ? 1 : -1 ) } )

     return 1
   endfunction
nnoremap <expr> <c-d> ScrollPopUp(1) ? '<esc>' : '<c-d>'
nnoremap <expr> <c-u> ScrollPopUp(0) ? '<esc>' : '<c-u>'
"---------------}}}
"-------------------------------}}}

" ale settings part2 -----------------------{{{
" Put these lines at the very end of your vimrc file.
" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
"---------------}}}

"theme actions-------------------------------------{{{
function! ChooseTheme()
        let themes=["default", "gruvbox", "gruvbox8", "PaperColor", "neodark", "gruvbox8_soft", "gruvbox8_hard"]
        let choices=GetConfirmChoicesString(themes)
        let choice=confirm("Which theme?", choices, 0)
        if choice==0
                return
        else
            execute "colorscheme ".themes[choice-1]
        endif
endfunction
function! ToggleDark()
        if &background=="light"
                set background=dark
        else
                set background=light
        endif
endfunction
nnoremap <leader>zt :call ChooseTheme()<CR>
nnoremap <leader>zd :call ToggleDark()<CR>
"------------}}}
