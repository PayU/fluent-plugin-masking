# fluent-plugin-masking

[![Known Vulnerabilities](https://snyk.io//test/github/PayU/fluent-plugin-masking/badge.svg?targetFile=Gemfile.lock)](https://snyk.io//test/github/PayU/fluent-plugin-masking?targetFile=Gemfile.lock) [![Build Status](https://travis-ci.com/PayU/fluent-plugin-masking.svg?branch=master)](https://travis-ci.com/PayU/fluent-plugin-masking)

# Overview
Fluentd filter plugin to mask sensitive or privacy records with `*******` in place of the original value. This data masking plugin protects data such as name, email, phonenumber, address, and any other field you would like to mask.

# Requirements
| fluent-plugin-masking    | fluentd    | ruby   |
| ---------------------    | ---------- | ------ |
| 1.2.x                    | 	>= v0.14.0 | >= 2.5 |


# Installation
Install with gem:

`fluent-gem install fluent-plugin-masking`

# Setup
In order to setup this plugin, the parameter `fieldsToMaskFilePath` needs to be a valid path to a file containing a list of all the fields to mask. The file should have a unique field on each line. These fields **are** case-sensitive (`Name` != `name`).

### Optional configuration
 - `fieldsToExcludeJSONPaths` - this field receives as input a comma separated string of JSON fields that should be excluded in the masking procedure. Nested JSON fields are supported by `dot notation` (i.e: `path.to.excluded.field.in.record.nestedExcludedField`) The JSON fields that are excluded are comma separated.  
This can be used for logs of registration services or audit log entries which do not need to be masked.

- `handleSpecialEscapedJsonCases` - a boolean value that try to fix special escaped json cases. this feature is currently on alpha stage (default: false). for more details about thoose special cases see [Special Json Cases](#Special-escaped-json-cases-handling)

An example with optional configuration parameters:
```
<filter "**">
  @type masking
  fieldsToMaskFilePath "/path/to/fields-to-mask-file"
  fieldsToExcludeJSONPaths "excludedField,exclude.path.nestedExcludedField"
  handleSpecialEscapedJsonCases true
</filter>
```

Example fields-to-mask-file:
```
name
email
phone/i # the '/i' suffix will make sure phone field will be case insensitive
```

# Quick Guide

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
  fieldsToExcludeJSONPaths "excludedField,exclude.path.nestedExcludedField"
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

A sample with exclude in use:
```
fluentd -c fluent.conf
echo '{ :body => "{\"first_name\":\"mickey\", \"type\":\"puggle\", \"last_name\":\"the-dog\", \"password\":\"d0g43u39\"}", "excludeMaskFields"=>"first_name,last_name"}' > /tmp/test.log
```

```
2019-12-01 14:25:53.385681000 +0300 maskme: {"message":"{ :body => \"{\\\"first_name\\\":\\\"mickey\\\", \\\"type\\\":\\\"puggle\\\", \\\"last_name\\\":\\\"the-dog\\\", \\\"password\\\":\\\"*******\\\"}\"}"}
```

# Run Unit Tests
```
gem install bundler
bundle install
ruby -r ./test/*.rb
```

# Special escaped json cases handling

