local zip = require 'zip'
local xml = require 'xml'
local i   = require 'inspect'

local zfile, err = zip.open('/home/paragasu/tmp/test.docx')
local file, err  = zfile:open('word/document.xml')
if not file then error(err) end
local doc = file:read('*a')
local str = string.gmatch(doc, '#%a+%.%a+%s?%a+#')
local tag = string.gsub(doc, '#%a+%.%a+%s?%a+#', function(s)
  print(s)
  return "hello"
end)
local data = xml.load(doc)
--for w in str  do print(w) end
