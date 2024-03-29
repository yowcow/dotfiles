local cmd = vim.cmd

cmd([[augroup filetyping]])
cmd([[autocmd!]])
cmd([[autocmd BufNewFile,BufRead *.psgi set filetype=perl]])
cmd([[autocmd BufNewFile,BufRead *.t set filetype=perl]])
cmd([[augroup END]])

cmd([[augroup tabstop]])
cmd([[autocmd!]])
cmd([[autocmd FileType make,go setlocal noexpandtab]])
cmd([[autocmd FileType xml,xhtml,html,smarty,json,yaml setlocal softtabstop=2 tabstop=2 shiftwidth=2]])
cmd(
	[[autocmd FileType javascript,javascript.jsx,javascriptreact,typescript,typescript.tsx,typescriptreact,vue,ruby,lua,sql setlocal softtabstop=2 tabstop=2 shiftwidth=2]]
)
cmd([[autocmd FileType markdown setlocal softtabstop=4 tabstop=4 shiftwidth=2]])
cmd([[autocmd FileType yaml setlocal indentkeys-=0#]])
cmd([[augroup END]])

cmd([[augroup bufwritepre]])
cmd([[autocmd!]])
cmd([[autocmd FileType * autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async = false })]])
-- cmd([[autocmd FileType php autocmd BufWritePre <buffer> lua vim.lsp.buf.format({ async = false })]])
-- cmd([[autocmd FileType go autocmd BufWritePre <buffer> silent! %!goimports]])
-- cmd([[autocmd FileType go autocmd BufWritePre <buffer> silent! %!gofmt]])
-- cmd([[autocmd FileType javascript,typescript,typescript.tsx autocmd BufWritePre <buffer> silent! EslintFixAll]])
-- cmd([[autocmd FileType json autocmd BufWritePre <buffer> silent! %!jq "."]])
-- cmd([[autocmd FileType yaml autocmd BufWritePre <buffer> silent! %!yamlfmt -in]])
cmd([[augroup END]])

cmd([[augroup term]])
cmd([[autocmd!]])
cmd([[autocmd TermOpen * startinsert]])
cmd([[augroup END]])
