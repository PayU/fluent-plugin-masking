require 'fluent/filter'
require_relative './helpers.rb'

module Fluent
  module Plugin
    class MaskingFilter < Filter
      include Helpers
      Fluent::Plugin.register_filter("masking", self) # for "@type masking" in configuration

      MASK_STRING = "*******"

      def strToHash(str)
        eval(str)
      end

      # returns the masked record
      # error safe method - if any error occurs the original record is returned
      def maskRecord(record)
        maskedRecord = record
        excludedFields = []
        begin
          @fieldsToExcludeJSONPathsArray.each do | field |
            field_value = myDig(record, field)
            if field_value != nil
              excludedFields = excludedFields + field_value.split(',')
            end
          end
        rescue Exception => e
          $log.error "Failed to find mask exclude record: #{e}"
        end
        begin
          recordStr = record.to_s
          if @useCaseInsensitiveFields == "true"
            recordStr = recordStr.downcase
          end

          @fields_to_mask_regex.each do | fieldToMaskRegex, fieldToMaskRegexStringReplacement |
            if !(excludedFields.include? @fields_to_mask_keys[fieldToMaskRegex])
              recordStr = recordStr.gsub(fieldToMaskRegex, fieldToMaskRegexStringReplacement) 
            end
          end

          maskedRecord = strToHash(recordStr)

        rescue Exception => e
          $log.error "Failed to mask record: #{e}"
        end

        maskedRecord
      end

      def initialize
        super
        @fields_to_mask = []
        @fields_to_mask_regex = {}
        @fields_to_mask_keys = {}
        @fieldsToExcludeJSONPathsArray = []
        @useCaseInsensitiveFields = "false"
      end

      # this method only called ones (on startup time)
      def configure(conf)
        super
        fieldsToMaskFilePath = conf['fieldsToMaskFilePath']
        fieldsToExcludeJSONPaths = conf['fieldsToExcludeJSONPaths']

        if conf["useCaseInsensitiveFields"] != nil && conf["useCaseInsensitiveFields"] == "true"
          @useCaseInsensitiveFields = "true"
        end

        if fieldsToExcludeJSONPaths != nil && fieldsToExcludeJSONPaths.size() > 0 
          fieldsToExcludeJSONPaths.split(",").each do | field |
            # To save splits we'll save the path as an array
            splitArray = field.split(".")
            symArray = []
            splitArray.each do | pathPortion |
              symArray.push(pathPortion.to_sym)
            end
            @fieldsToExcludeJSONPathsArray.push(symArray)
          end
        end

        File.open(fieldsToMaskFilePath, "r") do |f|
          f.each_line do |line|

            value = line.to_s # make sure it's string
            value = value.gsub(/\s+/, "") # remove spaces
            value = value.gsub('\n', '') # remove line breakers

            if @useCaseInsensitiveFields == "true"
              value = value.downcase
            end

            @fields_to_mask.push(value)

            hashObjectRegex = Regexp.new(/(?::#{value}=>")(.*?)(?:")/m) # mask element in hash object
            hashObjectRegexStringReplacement = ":#{value}=>\"#{MASK_STRING}\""
            @fields_to_mask_regex[hashObjectRegex] = hashObjectRegexStringReplacement
            @fields_to_mask_keys[hashObjectRegex] = value

            innerJSONStringRegex = Regexp.new(/(\\+)"#{value}\\+"\s*:\s*(\\+|\{).+?((?=(})|,( *|)(\s|\\+)\"(}*))|(?=}"$)|("}(?!\"|\\)))/m) # mask element in json string using capture groups that count the level of escaping inside the json string
            innerJSONStringRegexStringReplacement = "\\1\"#{value}\\1\":\\1\"#{MASK_STRING}\\1\""
            @fields_to_mask_regex[innerJSONStringRegex] = innerJSONStringRegexStringReplacement
            @fields_to_mask_keys[innerJSONStringRegex] = value
          end
        end

        puts "black list fields:"
        puts @fields_to_mask
      end

      def filter(tag, time, record)
        # This method implements the filtering logic for individual filters
        # It is internal to this class and called by filter_stream unless
        # the user overrides filter_stream.
        maskRecord(record)
      end

    end # end of MaskingFilter class definition
  end
end # end of 'module Fluent' definition