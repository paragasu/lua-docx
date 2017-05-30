# lua-docx
Lua library to generate word document from docx template file.


# Usage

```lua
local docx = require 'lua-docx'
local tpl  = docx:new('./tpl/docx-template.docx')
local ok   = tpl:replace({ 
  ['#matters.name'] = 'Some name',
  ['#matters.email'] = 'some@email.com'
})

-- save to given path
local rse  = tpl:save('./tmp/docx-file.docx')

-- send output to the browser
local res  = tpl:download()
```
