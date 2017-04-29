require 'test_helper'

class IpAddressValidatorTest < ActiveSupport::TestCase

  class TestModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :one
    attr_accessor :one_or_many
    attr_accessor :many

    validates :one,           'incline/ip_address' => { no_mask: true }
    validates :one_or_many,   'incline/ip_address' => true
    validates :many,          'incline/ip_address' => { require_mask: true }
  end

  def setup
    @item = TestModel.new(one: '192.168.0.1', one_or_many: '192.168.0.1', many: '192.168.0.0/24')
  end

  test 'initial values should be valid' do
    assert @item.valid?
  end

  test 'ip_address validator ignores blank values' do
    [ :one, :one_or_many, :many ].each do |attr|
      setter = :"#{attr}="
      val = @item.send(attr)

      @item.send setter, nil
      assert @item.valid?,    "#{attr} should allow nil"

      @item.send setter, ''
      assert @item.valid?,    "#{attr} should allow ''"

      @item.send setter, '   '
      assert @item.valid?,    "#{attr} should allow '   '"

      @item.send setter, val
      assert @item.valid?,    "#{attr} should allow '#{val}'"
    end
  end

  test 'one should not accept a mask' do
    @item.one = '192.168.0.0/24'
    assert_not @item.valid?
    assert @item.errors[:one].to_s =~ /must not contain a mask/i
  end

  test 'many should require a mask' do
    @item.many = '192.168.0.1'
    assert_not @item.valid?
    assert @item.errors[:many].to_s =~ /must contain a mask/i
  end

  test 'one_or_many should allow a mask' do
    @item.one_or_many = '102.168.0.1/24'
    assert @item.valid?
  end

  test 'should allow valid addresses' do
    %w(
        127.0.0.1
        127.0.0.1/8
        127.0.0.1/16
        127.0.0.1/24
        1.2.3.4/32
        0.0.0.0
        255.255.255.255
        ::
        ::1
        abcd::1234
        abcd::/64
        1:2:3:4:a:b:c:d
        1111:2222:3333:4444:aaaa:bbbb:cccc:dddd/112
        fe80::1234/128
    ).each do |addr|
      @item.one_or_many = addr
      assert @item.valid?, "Should allow '#{addr}'."
    end
  end

  test 'should not allow invalid addresses' do
    safe = @item.one_or_many
    %w(
        100.200.300.400
        1111::2222::3333
        1234:5678:90ab:cdef:ghij:klmn:opqr:stuv
        12345::
        ::12345
        1.2.3
        1.2.3.4/33
        1.2.3.4.5
        ::1/129
        1::2::3
    ).each do |addr|
      @item.one_or_many = addr
      assert_not @item.valid?,  "Should not allow '#{addr}'."
      assert @item.errors[:one_or_many].to_s =~ /not a valid ip address/i, "address '#{addr}' did not fail for the expected reason"
      @item.one_or_many = safe
      assert @item.valid?, "Should allow '#{safe}'."
    end
  end


end
