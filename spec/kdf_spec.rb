# frozen_string_literal: true

# (c) 2017 Ribose Inc.

require 'spec_helper'

describe Botan::KDF.method(:kdf) do
  it 'produces the expected output' do
    expect(
      Botan::KDF.kdf(algo: 'KDF2(SHA-1)',
                     secret: Botan.hex_decode('701F3480DFE95F57941F804B1B2413EF'),
                     key_length: 7,
                     salt: Botan.hex_decode('55A4E9DD5F4CA2EF82'),
                     label: '')
    ).to eql Botan.hex_decode('fbecb3ccfeec6e')
  end
end

describe Botan::KDF.method(:pbkdf) do
  let(:result) do
    Botan::KDF.pbkdf(algo: 'PBKDF2(SHA-1)',
                     password: '',
                     key_length: 32,
                     iterations: 10_000,
                     salt: Botan.hex_decode('0001020304050607'))
  end

  it 'produces the expected output' do
    expect(result).to eql Botan.hex_decode('59B2B1143B4CB1059EC58D9722FB1C72471E0D85C6F7543BA5228526375B0127')
  end
end

describe Botan::KDF.method(:pbkdf_timed) do
  let(:salt) { Botan::RNG.get(Botan::DEFAULT_KDF_SALT_LENGTH) }
  let(:result) do
    Botan::KDF.pbkdf_timed(algo: 'PBKDF2(SHA-256)',
                           password: 'xyz',
                           salt: salt,
                           key_length: 32,
                           milliseconds: 200)
  end
  let(:iterations) { result[:iterations] }
  let(:key) { result[:key] }

  it 'uses a valid number of iterations' do
    expect(iterations).to be >= 1
  end

  it 'produces an output of the correct size' do
    expect(key.bytesize).to be 32
  end

  it 'produces the same output with the same inputs (timed and non-timed)' do
    expect(
      Botan::KDF.pbkdf(algo: 'PBKDF2(SHA-256)',
                       password: 'xyz',
                       key_length: 32,
                       iterations: iterations,
                       salt: salt)
    ).to eql key
  end
end

