# fluent-plugin-masking

## Overview
Fluentd filter plugin to mask sensitive or privacy records with `*******` in place of the original value. This data masking plugin protects data such as name, email, phonenumber, address, and any other field you would like to mask.

## Requirements
| fluent-plugin-masking    | fluentd    | ruby   |
| ---------------------    | ---------- | ------ |
| 1.0.x                    | 	>= v0.14.0 | >= 2.1 |


## Installation
Install with gem:

`gem install fluent-plugin-masking`

## Setup
In order to setup this plugin, the paremeter `fieldsToMaskFilePath` needs to be a valid path to a file containing a list of all the fields that need to be masked. The file should have a unique field on each line in the file. These fields **are** case-sensitive (`Name` != `name`).

This is configured as shown below:
```
<filter "**">
  @type masking
  fieldsToMaskFilePath "/path/to/fields-to-mask-file"
</filter>
```

Example file:
```
name
email
phone
```


## Quick Guide

### Configuration:
```
# fluent.conf
----------------------------------
<source>
  @type dummy
  tag maskme
  dummy [
      {"id": "1", "first_name":"Mickey", "last_name": "Thedog", "title": "Mr."},
      {"id": "2", "first_name":"Nully", "last_name": "Null", "title": "Ms.", "address": "Earth", "age": 4, "phone": "+1(863)-382-3888"}      
    ]
</source>

<filter "**">
  @type masking
  fieldsToMaskFilePath "/path/to/fields-to-mask-file"
</filter>

<match "**">
  @type stdout
</match>



# /path/to/fields-to-mask-file
----------------------------------
first_name
last_name
address
phone
```

### Result
This sample result is created from the above configuration file `fluent.conf`. As expected, the following fields configured to be masked are masked with `*******` in the output.

```
2019-09-05 17:35:09.072275000 +0300 maskme: {"id":"1","first_name":"*******","last_name":"*******","title":"Mr."}
2019-09-05 17:35:10.095184000 +0300 maskme: {"id":"2","first_name":"*******","last_name":"*******","title":"Ms.","address":"*******","age":4,"phone":"*******"}
```