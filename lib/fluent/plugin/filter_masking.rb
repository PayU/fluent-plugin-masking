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
      # error safe method - if any error occurs
      # the original record is return
      def maskRecord(record)
        maskedRecord = record
        
        begin
          recordStr = record.to_s
          @fields_to_mask.each do | fieldToMask |
            recordStr = recordStr.gsub(/(?::#{fieldToMask}=>")(.*?)(?:")/m, ":#{fieldToMask}=>\"#{MASK_STRING}\"") # mask element in hash object
            recordStr = recordStr.gsub(/\\"#{fieldToMask}\\":\\.+?((?=(}\\",)|,( *|)(\s|\\)\")|(?=}"$))/m, "\\\"#{fieldToMask}\\\":\\\"#{MASK_STRING}\\\"") # mask element in json string
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