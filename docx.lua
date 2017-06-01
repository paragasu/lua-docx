local zip = require 'brimworks.zip'
local xml = require 'xml'
local lfs = require 'lfs'
local i = require 'inspect'
local m = {}

function m:new(filepath)
  if type(filepath) ~= 'string' then error('Invalid docx file') end
  if not string.match(filepath, '%.docx') then error('Only docx file supported') end
  if not m.file_exists(filepath) then error('File '.. filepath .. ' not exists') end
  self.doc_file = filepath 
  self.tag_pattern = '#%a+%.%a+%s?%a+#'
  return setmetatable(m, self)
end

function m:get_docx_document_content()
  local doc = m:get_cleaned_docx_file()
  local ar, err = zip.open(doc)
  if not ar then return error('Failed to open ' .. doc .. ' : ' .. err) end
  local file_idx = ar:name_locate('word/document.xml')
  local file, err  = ar:open(file_idx, zip.FL_UNCHANGED)
  if not file then return error('Cannot read document file: ' .. err) end
  local stat = ar:stat(file_idx) 
  return file:read(stat.size) 
end

function m:get_cleaned_docx_file()
  local doc = m.get_filename(self.doc_file)
  local tmp_doc = '/tmp/' .. doc
  if not m.file_exists(tmp_doc) then m:clean_docx_xml() end
  if not m.file_exists(tmp_doc) then return error('Fail to generate cleaned docx with libreoffice') end
  return tmp_doc
end

-- get the filename given full path
-- @param string path
-- @return string filename
function m.get_filename(path)
  if type(path) ~= 'string' then error('Invalid filename') end
  return string.match(path, '[%w+%s%-_]+%.docx')
end

-- check if file exists
-- @param string full path to filename
-- @return boolean
function m.file_exists(filename)
  if type(filename)~="string" then return false end
  return os.rename(filename, filename) and true or false
end

function m:replace(tags)
  local tpl, err  = m:get_docx_document_content() 
  return string.gsub(tpl, self.tag_pattern, tags)
end

function m:download()
  -- prompt browser to download file / open with msword
end

-- clean docx xml using libreoffice
function m:clean_docx_xml()
  local cmd = 'libreoffice --headless --convert-to docx --outdir /tmp ' .. self.doc_file
  local doc = assert(io.popen(cmd))   
  if not doc then error("Failed to clean up docx. Libreoffice installed?") end
  for line in doc:lines() do
    print(line)
  end
end

return m
