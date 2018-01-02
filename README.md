# lua-docx
Simple lua library to replace tags in the docx template file.


# Usage

```lua
local docx = require 'docx'
local doc  = docx:new('./tpl/docx-template.docx', '/home/myhome/tmpdir')
local ok   = doc:replace({ 
  ['#matters.name#'] = 'Some name',
  ['#matters.email#'] = 'some@email.com'
})

-- copy docx file to public web directory
local res  = doc:move('/var/www/public/20170601.docx')

```

Forward the browser url point to this file eg: https://mydomain.com/20170601.docx

# Usage

### new(docx\_tpl\_path, tmp\_file\_dir)
- docx\_tpl\_path _string_ docx file with full path 
- tmp\_file\_dir _string_ output file directory

### replace(tags)
- tags _table_ table of tag -> value

### move(output\_file)
- output\_file _string_ move generated file to given directory and filename


# Installation

It is important to configure the lua-docx-xml-cleaner in order for lua-docx to work properly.


```
#luarocks install --server=http://luarocks.org/dev lua-zip
#luarocks install lua-docx-xml-cleaner
#luarocks install lua-docx

```
