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
In order to setup this plugin, the parameter `fieldsToMaskFilePath` needs to be a valid path to a file containing a list of all the fields to mask. The file should have a unique field on each line. These fields **are** case-sensitive (`Name` != `name`).

This is configured as shown below:
```
<filter "**">
  @type masking
  fieldsToMaskFilePath "/path/to/fields-to-mask-file"
</filter>
```

Example fields-to-mask-file:
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
  @type tail
  path /tmp/test.log
  pos_file /tmp/test.log.pos
  tag maskme
  format none
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
password
email
```

### Result

To run the above configuration, run the following commands:
```
fluentd -c fluent.conf
echo '{ :body => "{\"first_name\":\"mickey\", \"type\":\"puggle\", \"last_name\":\"the-dog\", \"password\":\"d0g43u39\"}"}' > /tmp/test.log
```

This sample result is created from the above configuration file `fluent.conf`. As expected, the following fields configured to be masked are masked with `*******` in the output.

```
2019-09-15 16:12:50.359191000 +0300 maskme: {"message":"{ :body => \"{\\\"first_name\\\":\\\"*******\\\", \\\"type\\\":\\\"puggle\\\", \\\"last_name\\\":\\\"*******\\\", \\\"password\\\":\\\"*******\\\"}\"}"}
```