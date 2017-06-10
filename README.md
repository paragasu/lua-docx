# lua-docx
Simple lua library to replace tags in the docx template file.


# Usage

```lua
local docx = require 'docx'
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
#aptitude install libreoffice-writer libreoffice-base libzip-dev libreoffice-java-common
#luarocks install --server=http://luarocks.org/dev lua-zip
#luarocks install lua-resty-exec
#luarocks install lua-docx
```

We use non blocking `sockexec` to offload the task of generating a cleaner XML docx.
The docx generate by Ms Work is very dirty and the XML makeup split the tag in multiple parts.
For this we use `libreoffice` to process the docx file.


```
$cd /usr/src
$git clone https://github.com/skarnet/skalibs
$git checkout v2.4.0.2
$configure
$make
#make install
```

### Install sockexec

```
$git clone https://github.com/jprjr/sockexec
$make
$make install
```

### Install systemd service

Create the file `sockexec.service` in `/etc/systemd/system` folder

```
[Unit]
description=sockexec
After=network.target

[Service]
ExecStart=/usr/local/bin/sockexec /tmp/exec.sock
User=nobody

[Install]
WantedBy=multi-user.target
```

Make sure the sock server is running

```
#systemctl start sockexec
#systemctl enable sockexec
```

# Permission issue note

- `libreoffice` require jdk to work properly. The same use must own the `nginx` process and and `/tmp/exec.sock`
-  Make sure the JAVA_HOME and HOME env is set.

