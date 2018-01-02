# lua-docx
Simple lua library to replace tags in the docx template file.


# Usage

```lua
local sock_file = '/home/rogon/tmp/exec.sock' 
local tmp_dir = '/home/myhome/tmpdir'

local docx = require 'docx'
local docx_cleaner = require 'docx-cleaner'

local dc = docx_cleaner.new(tmp_dir, sock_file_path)
local cleaned_docx = dc:clean_xml(./tmp/docx-tpl.docx')

local doc  = docx.new(tmp_dir)
local ok, err = doc:replace_tags(cleaned_docx, { 
  ['#matters.name#'] = 'Some name',
  ['#matters.email#'] = 'some@email.com'
})

-- copy docx file to public web directory
local res, err = os.rename(cleaned_docx, '/var/www/public/20170601.docx')

```
Forward the browser url point to this file eg: https://mydomain.com/20170601.docx

# API

### new(tmp\_file\_dir)
- tmp\_file\_dir _string_ output file directory


### replace_tags(docx\_tpl\_path, tags)
- docx\_tpl\_path _string_ docx file with full path 
- tags _table_ table of tag -> value
- return boolean, err 


# Installation

It is important to configure the lua-docx-xml-cleaner in order for lua-docx to work properly.


```
#luarocks install --server=http://luarocks.org/dev lua-zip
#luarocks install lua-docx-xml-cleaner
#luarocks install lua-docx

```
