# fluent-plugin-masking

## Overview
Fluentd filter plugin to mask fields in log records with `****` in place of the original value. This data masking plugin protects privacy data such as name, email, phone-number, address, and any other field you would like to mask.

## Requirements
| fluent-plugin-masking    | fluentd    | ruby   |
| ---------------------    | ---------- | ------ |
| 1.0.3                    | 	v0.14.x | >= 2.1 |


## Installation
Install with gem:

`gem install fluent-plugin-masking`

## Quick Guide

### Configuration:
```
# fluent.conf file
----------------------------------
  <filter "**">
    @type masking
    fieldsToMaskFilePath "/fluentd/etc/fields-to-mask"
  </filter>


# /fluentd/etc/fields-to-mask file
----------------------------------
email
first_name
last_name
```

### Result
This sample result has made with the above configuration into "fluent.conf".

```

```
