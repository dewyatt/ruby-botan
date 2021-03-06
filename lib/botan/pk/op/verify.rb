# frozen_string_literal: true

# (c) 2017 Ribose Inc.

require 'ffi'

require 'botan/defaults'
require 'botan/error'
require 'botan/ffi/libbotan'
require 'botan/pk/publickey'
require 'botan/utils'

module Botan
  module PK
    # Public Key Verify Operation
    #
    # See {Botan::PK::PublicKey#verify} for a simpler interface.
    class Verify
      # @param key [Botan::PK::PublicKey] the public key
      # @param padding [String] the padding method name
      def initialize(key:, padding: nil)
        padding ||= Botan::DEFAULT_EMSA[key.algo]
        unless key.instance_of?(PublicKey)
          raise Botan::Error, 'Verify requires an instance of PublicKey'
        end
        ptr = FFI::MemoryPointer.new(:pointer)
        flags = 0
        Botan.call_ffi(:botan_pk_op_verify_create,
                       ptr, key.ptr, padding, flags)
        ptr = ptr.read_pointer
        if ptr.null?
          raise Botan::Error, 'botan_pk_op_verify_create returned NULL'
        end
        @ptr = FFI::AutoPointer.new(ptr, self.class.method(:destroy))
      end

      # @api private
      def self.destroy(ptr)
        LibBotan.botan_pk_op_verify_destroy(ptr)
      end

      # Adds more data to the message currently being verified.
      #
      # @param msg [String] the data to add
      # @return [self]
      def update(msg)
        msg_buf = FFI::MemoryPointer.from_data(msg)
        Botan.call_ffi(:botan_pk_op_verify_update, @ptr, msg_buf, msg_buf.size)
        self
      end

      # Checks the signature against the previously-provided data.
      #
      # @param signature [String] the signature to check
      # @return [Boolean] true if the signature is valid
      def check_signature(signature)
        sig_buf = FFI::MemoryPointer.from_data(signature)
        # workaround 2.2.0 release bug
        if LibBotan::LIB_VERSION == [2, 2, 0]
          rc = LibBotan.botan_pk_op_verify_finish(@ptr, sig_buf, sig_buf.size)
          raise Botan::Error, 'FFI call unexpectedly failed' \
            unless [0, -1].include?(rc)
        else
          rc = Botan.call_ffi_rc(:botan_pk_op_verify_finish,
                                 @ptr, sig_buf, sig_buf.size)
        end
        rc.zero?
      end

      def inspect
        Botan.inspect_ptr(self)
      end

      alias << update
    end # class
  end # module
end # module

