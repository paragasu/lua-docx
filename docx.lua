-- Author: Jeffry L <paragasu@gmail.com>

local zip = require 'brimworks.zip'
local u = require 'util'
local i = require 'inspect'

local m = {}
m.__index = m

-- @param string filepath full filename path to the docx template
-- @param string tmp directory to process the file
--        using /tmp end up with Renaming temporary file failed: Operation not permitted
--        error. But using other directory is fine.
function m.new(tmp_dir)
  local self = setmetatable({}, m)
  self.tmp_dir = tmp_dir
  ngx.log(ngx.NOTICE, "tmp_dir: " .. self.tmp_dir)
  return self
end

function m:file(docx_file)
  m:validate_file(filepath)
  self.docx = filepath;
  self.ar = nil;
end

function m:validate_file(filepath)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported ' .. filepath) end
  if string.find(filepath, '%.%/') then error('Relative path using ./ not supported ' .. filepath) end
  if string.find(filepath, '%~%/') then error('Relative path using ~/ not supported ' .. filepath) end
  if not u.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
  if not tmp_dir then error("Writable temporary directory not provided") end
end

function m:replace(tags)
  ngx.log(ngx.NOTICE, "open zip " .. self.docx)
  -- file must be writeable
  if not u.file_exists(self.docx) then error(self.docx .. "not exists") end 
  if not u.is_writeable(self.docx) then u.set_file_writeable(self.docx) end

  -- escape xml tags
  local escaped_tags = m:escape_xml_chars(tags)
  self.ar = assert(zip.open(self.docx)) 
  
  m:replace_docx_document()
  m:replace_docx_header()
  m:replace_docx_footer()

  self.ar:close()
end

function m:escape_xml_chars(tags)
  local data = {}
  for tag, value in pairs(tags) do
    data[tag] = u.xml_escape_chars(value)
  end
  return data or ''
end

function m:replace_docx_document()
  local docume_idx = self.ar:name_locate('word/document.xml')
  local docume_src = m:get_docx_xml_content(self.ar, docume_idx, escaped_tags)
  self.ar:replace(docume_idx, 'string', docume_src) 
end

function m:replace_docx_header()
  local header_idx = self.ar:name_locate('word/header1.xml')
  if header_idx then
    local header_src = m:get_docx_xml_content(self.ar, header_idx, escaped_tags)
    self.ar:replace(header_idx, 'string', header_src) 
  end
end

function m:replace_docx_footer()
  local footer_idx = self.ar:name_locate('word/footer1.xml')
  if footer_idx then
    local footer_src = m:get_docx_xml_content(self.ar, footer_idx, escaped_tags)
    self.ar:replace(footer_idx, 'string', footer_src) 
  end
end

-- get the content of xml file inside the zip
-- @param string word/document.xml, word/footer1.xml or word/header1.xml
function m:get_docx_xml_content(ar, idx, tags)
  local file = assert(ar:open(idx))
  local stat = ar:stat(idx) 
  local tpl  = file:read(stat.size) 
  file:close()
  return string.gsub(tpl, '#%a+%.[%a%s%d]+#', tags) or ''
end

return m
