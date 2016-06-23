require 'openssl'
require 'base64'

module Tidas
  module Utilities
    class KeyBuilder
      # ecPublicKey = '1.2.840.10045.2.1'
      KEY_TYPE_BLOB_KEY_TYPE_ID = OpenSSL::ASN1::ObjectId.new('1.2.840.10045.2.1')
      # prime256v1 = '1.2.840.10045.3.1.7'
      KEY_TYPE_BLOB_CURVE_ID = OpenSSL::ASN1::ObjectId.new('1.2.840.10045.3.1.7')
      KEY_SEQ = OpenSSL::ASN1::Sequence.new([KEY_TYPE_BLOB_KEY_TYPE_ID, KEY_TYPE_BLOB_CURVE_ID])


      def self.init_with_bytes(bytes)
        k = Tidas::Utilities::KeyBuilder.new({bytes: bytes})
        k.validate
      end

      def self.init_with_hex_key_bytes(hex_key_bytes)
        k = Tidas::Utilities::KeyBuilder.new({hex_key_bytes: hex_key_bytes})
        k.validate
      end

      def export_pub(file = nil)
        unless file
          pub
        else
          File.open(file, 'w') {|f| f.write(pub)}
        end
      end

      def validate
        begin
          OpenSSL::PKey::EC.new(export_pub).check_key
        rescue OpenSSL::PKey::ECError => err
          return Tidas::Utilities::KeyBuilder::KeyError.init_with_error(err)
        end
        self
      end

      private

      def initialize(attributes)
        unless bytes = attributes[:bytes]
          pub_key_hex_bytes = attributes[:hex_key_bytes]
          bytes = [pub_key_hex_bytes].pack("H*")
        end
        @ASN1_key_bits = OpenSSL::ASN1::BitString.new(bytes)
      end

      def key
        pub_key_seq = OpenSSL::ASN1::Sequence.new([KEY_SEQ, @ASN1_key_bits])
      end

      def pub
        pubstr  =  "-----BEGIN PUBLIC KEY-----\n"
        pubstr  +=  Base64.encode64(key.to_der)
        pubstr  +=  "-----END PUBLIC KEY-----\n"

        pubstr
      end

      public

      class KeyError
        attr_reader :error

        def self.init_with_error(err)
          KeyError.new({error: err})
        end

        def export_pub
          self
        end

        private

        def initialize(attributes)
          @error = attributes[:error]
        end
      end

    end


  end
end

if ARGV.length != 1
  puts "Err: please pass in exactly one argument\n(Does your data have spaces? Enclose it in quotes!)"
else
  key = Tidas::Utilities::KeyBuilder.init_with_hex_key_bytes(ARGV[0].gsub(' ', ''))
  puts key.export_pub
end
