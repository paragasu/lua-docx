# lua-docx
Simple lua library to replace tags in the docx template file.


# Usage

```lua
local docx = require 'lua-docx'
local doc  = docx:new('./tpl/docx-template.docx')
local ok   = doc:replace({ 
  ['#matters.name'] = 'Some name',
  ['#matters.email'] = 'some@email.com'
})

-- copy docx file to public web directory
local res  = doc:move('/var/www/public/20170601.docx')

```

Forward the browser url point to this file eg: https://mydomain.com/20170601.docx

# Installation


```
#aptitude install libreoffice-writer libreoffice-base libzip-dev
#luarocks install --server=http://luarocks.org/dev lua-zip
#luarocks install lua-docx
```
