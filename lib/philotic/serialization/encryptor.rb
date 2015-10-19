require 'encryptor'
require 'philotic/serialization/serializer'
require 'base64'

module Philotic
  module Serialization
    module Encryptor
      extend self

      def content_type
        'application/json'
      end

      def serialization
        :encrypted
      end

      def default_encryption_key
        Philotic.config.encryption_key
      end

      def random_salt
        Base64.encode64 SecureRandom.random_bytes(256)
      end

      def default_algorithm
        'aes-256-cbc'
      end

      def random_iv(algorithm = default_algorithm)
        OpenSSL::Cipher::Cipher.new(algorithm).random_iv
      end

      def key
        @key ||= default_encryption_key
      end

      def dump(payload, metadata)
        metadata[:headers][:encryption] ||= {}
        algorithm                       = (metadata[:headers][:encryption][:algorithm] ||= default_algorithm)
        iv                              = Base64.decode64(metadata[:headers][:encryption][:iv] ||= Base64.encode64(random_iv(algorithm)))
        salt                            = Base64.decode64(metadata[:headers][:encryption][:salt] ||= Base64.encode64(random_salt))
        Base64.encode64 ::Encryptor.encrypt(payload, key: key, iv: iv, salt: salt)
      end

      def load(payload, metadata)
        headers = metadata[:headers].deep_dup.deep_symbolize_keys

        iv = Base64.decode64 headers[:encryption][:iv]
        salt = Base64.decode64 headers[:encryption][:salt]
        ::Encryptor.decrypt(Base64.decode64(payload), key: key, iv: iv, salt: salt)
      end
    end
  end
end
Philotic::Serialization::Serializer.register Philotic::Serialization::Encryptor