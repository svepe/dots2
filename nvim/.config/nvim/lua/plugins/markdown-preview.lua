-- markdown-preview — live preview in the browser (opens the system default).
-- Toggle with :MarkdownPreviewToggle. Ships a prebuilt server that needs a
-- one-time install; the PackChanged hook runs it on install/update.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local d = ev.data
    if d.spec and d.spec.name == "markdown-preview.nvim" and d.kind ~= "delete" then
      vim.fn["mkdp#util#install"]()
    end
  end,
})
vim.pack.add({ { src = "https://github.com/iamcco/markdown-preview.nvim" } })
