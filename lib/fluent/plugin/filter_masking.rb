require 'fluent/filter'

module Fluent
  module Plugin
    class MaskingFilter < Filter
      Fluent::Plugin.register_filter("masking", self) # for "@type masking" in configuration

      MASK_STRING = "*******"

      def strToHash(str)
        eval(str)
      end

      # returns the masked record
      # error safe method - if any error occurs the original record is returned
      def maskRecord(record)
        maskedRecord = record
        
        begin
          recordStr = record.to_s
          @fields_to_mask_regex.each do | fieldToMaskRegex, fieldToMaskRegexStringReplacement |
            recordStr = recordStr.gsub(fieldToMaskRegex, fieldToMaskRegexStringReplacement) 
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
      end

      # this method only called ones (on startup time)
      def configure(conf)
        super
        fieldsToMaskFilePath = conf['fieldsToMaskFilePath']

        File.open(fieldsToMaskFilePath, "r") do |f|
          f.each_line do |line|

            value = line.to_s # make sure it's string
            value = value.gsub(/\s+/, "") # remove spaces
            value = value.gsub('\n', '') # remove line breakers

            @fields_to_mask.push(value)

            hashObjectRegex = Regexp.new(/(?::#{value}=>")(.*?)(?:")/m) # mask element in hash object
            hashObjectRegexStringReplacement = ":#{value}=>\"#{MASK_STRING}\""
            @fields_to_mask_regex[hashObjectRegex] = hashObjectRegexStringReplacement

            innerJSONStringRegex = Regexp.new(/(\\+)"#{value}\\+":\\+.+?((?=(})|,( *|)(\s|\\+)\")|(?=}"$))/m) # mask element in json string using capture groups that count the level of escaping inside the json string
            innerJSONStringRegexStringReplacement = "\\1\"#{value}\\1\":\\1\"#{MASK_STRING}\\1\""
            @fields_to_mask_regex[innerJSONStringRegex] = innerJSONStringRegexStringReplacement
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