local M = {}

function M.attacher(client)
  client.resolved_capabilities.document_formatting = false
  client.resolved_capabilities.document_range_formatting = false
end

M.settings = {
    ['rust-analyzer'] = {},
}

return M
