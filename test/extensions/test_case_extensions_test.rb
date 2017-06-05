require 'test_helper'

class TestCaseExtensionsTest < ActiveSupport::TestCase

  TEST_TABLE_NAME = "test_table_#{SecureRandom.random_number(1<<16).to_s(16).rjust(4,'0')}"
  TEST_TABLE_CLASS = TEST_TABLE_NAME.classify.to_sym

  class TestRamModel
    include ActiveModel::Model
    include ActiveModel::Validations

    attr_accessor :recaptcha, :email, :ip_any, :ip_mask, :ip_nomask, :session, :safe_name

    validates :recaptcha, 'incline/recaptcha' => true
    validates :email, 'incline/email' => true
    validates :ip_any, 'incline/ip_address' => true
    validates :ip_mask, 'incline/ip_address' => { require_mask: true }
    validates :ip_nomask, 'incline/ip_address' => { no_mask: true }
    validates :safe_name, 'incline/safe_name' => true
  end

  def with_db_model
    begin
      # Create a test table.
      silence_stream STDOUT do
        ActiveRecord::Migration::create_table TEST_TABLE_NAME do |t|
          t.integer :group,       null: false
          t.string  :name,        null: false,  limit: 30
          t.string  :description,               limit: 100
        end
      end

      # And then create a test model.
      eval <<-EOM
class #{TEST_TABLE_CLASS} < ActiveRecord::Base
  self.table_name = #{TEST_TABLE_NAME.inspect}

  validates :group,
      presence: true

  validates :name,
      presence: true,
      length: { minimum: 5, maximum: 30 },
      uniqueness: { case_sensitive: false, scope: :group }

  validates :description,
      length: { maximum: 100 }
end
      EOM

      model_class = self.class.const_get TEST_TABLE_CLASS
      item = model_class.new(group: 1, name: 'Hello', description: 'World')

      yield model_class, item
    ensure
      # Undefine the model class (or at least remove it from the Object namespace).
      begin
        self.class.send :remove_const, TEST_TABLE_CLASS
      rescue
        Incline::Log::error 'Failed to remove test model class.'
      end

      # Remove the table from the database.
      begin
        silence_stream STDOUT do
          ActiveRecord::Migration::drop_table TEST_TABLE_NAME
        end
      rescue
        Incline::Log::error 'Failed to drop test model table.'
      end
    end
  end

  def setup
    @item = TestRamModel.new(session: 99, email: 'user@example.com', recaptcha: Incline::Recaptcha::DISABLED)
  end

  test 'have extension methods' do
    assert respond_to?(:is_logged_in?)
    assert respond_to?(:log_in_as)
    assert respond_to?(:assert_required)
    assert respond_to?(:assert_max_length)
    assert respond_to?(:assert_min_length)
    assert respond_to?(:assert_uniqueness)
    assert respond_to?(:assert_recaptcha_validation)
    assert respond_to?(:assert_email_validation)
    assert respond_to?(:assert_ip_validation)
    assert respond_to?(:assert_safe_name_validation)
  end

  test 'item should be valid' do
    with_db_model do |klass,item|
      assert item.valid?
    end
    assert @item.valid?
  end

  test 'item should require group' do
    with_db_model do |klass,item|
      assert_required item, :group
    end
  end

  test 'item should require name' do
    with_db_model do |klass,item|
      assert_required item, :name
    end
  end

  test 'item name should have min length' do
    with_db_model do |klass,item|
      assert_min_length item, :name, 5
    end
  end

  test 'item name should have max length' do
    with_db_model do |klass,item|
      assert_max_length item, :name, 30
    end
  end

  test 'item name should be unique within group' do
    with_db_model do |klass,item|
      assert_uniqueness item, :name, group: 2
    end
  end

  test 'item description should have max length' do
    with_db_model do |klass,item|
      assert_max_length item, :description, 100
    end
  end

  test 'item recaptcha should pass validation' do
    assert_recaptcha_validation @item, :recaptcha
  end

  test 'item email should pass validation' do
    assert_email_validation @item, :email
  end

  test 'item ips should pass validation' do
    assert_ip_validation @item, :ip_any
    assert_ip_validation @item, :ip_mask, :require_mask
    assert_ip_validation @item, :ip_nomask, :deny_mask
  end

  test 'item safe_name should pass validation' do
    assert_safe_name_validation @item, :safe_name, 10
  end

  test 'item description should not be required' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_required item, :description }
    end
  end

  test 'item description length is not limited to 50, 101, or 10' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_max_length item, :description, 50 }
      assert_raises(Minitest::Assertion) { assert_max_length item, :description, 101 }
      assert_raises(Minitest::Assertion) { assert_min_length item, :description, 10 }
    end
  end

  test 'item name is unique across descriptions' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_uniqueness item, :name, description: 'something else' }
    end
  end

  test 'item description is not a recaptcha field' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_recaptcha_validation item, :description }
    end

  end

  test 'item description is not an ip address field' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_ip_validation item, :description }
    end
  end

  test 'item description is not an email address field' do
    with_db_model do |klass,item|
      assert_raises(Minitest::Assertion) { assert_email_validation item, :description }
    end
  end

  test 'item description is not a safe name field' do
    with_db_model do |klass, item|
      assert_raises(Minitest::Assertion) { assert_safe_name_validation item, :description }
    end
  end

  DEFAULT_ACCESS_TEST_ANON = <<-EOC
test "should not allow access to something for anonymous" do
path = foo_path
get(path)
assert_redirected_to incline.login_path
end
  EOC

  DEFAULT_ACCESS_TEST_ANY = <<-EOC
test "should not allow access to something for any user" do
user = incline_users(:basic)
log_in_as user
path = foo_path
get(path)
assert_redirected_to main_app.root_path
end
  EOC

  DEFAULT_ACCESS_TEST_ADMIN = <<-EOC
test "should allow access to something for admin user" do
user = incline_users(:admin)
log_in_as user
path = foo_path
get(path)
assert_response :success
end
  EOC

  test 'access_tests_for default tests are good' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, DEFAULT_ACCESS_TEST_ANY, DEFAULT_ACCESS_TEST_ADMIN ].join
    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path'
    assert_equal valid, code
  end

  test 'access_tests_for respects allow_anon' do
    valid = [ <<-EOC, DEFAULT_ACCESS_TEST_ANY, DEFAULT_ACCESS_TEST_ADMIN ].join
test "should allow access to something for anonymous" do
path = foo_path
get(path)
assert_response :success
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', allow_anon: true

    assert_equal valid, code
  end

  test 'access_tests_for respects allow_any_user' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, <<-EOC, DEFAULT_ACCESS_TEST_ADMIN ].join
test "should allow access to something for any user" do
user = incline_users(:basic)
log_in_as user
path = foo_path
get(path)
assert_response :success
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', allow_any_user: true

    assert_equal valid, code
  end

  test 'access_tests_for respects allow_admin' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, DEFAULT_ACCESS_TEST_ANY, <<-EOC ].join
test "should not allow access to something for admin user" do
user = incline_users(:admin)
log_in_as user
path = foo_path
get(path)
assert_redirected_to main_app.root_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', allow_admin: false

    assert_equal valid, code
  end

  test 'access_tests_for respects allow_groups' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, DEFAULT_ACCESS_TEST_ANY, DEFAULT_ACCESS_TEST_ADMIN, <<-EOC ].join
test "should allow access to something for Group 1 member" do
user = incline_users(:basic)
group = Incline::AccessGroup.find_or_create_by(name: "Group 1")
user.groups << group
log_in_as user
path = foo_path
get(path)
assert_response :success
end
test "should allow access to something for Group 2 member" do
user = incline_users(:basic)
group = Incline::AccessGroup.find_or_create_by(name: "Group 2")
user.groups << group
log_in_as user
path = foo_path
get(path)
assert_response :success
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', allow_groups: [ 'Group 1', 'Group 2' ]
    assert_equal valid, code
  end

  test 'access_tests_for respects deny_groups' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, DEFAULT_ACCESS_TEST_ANY, DEFAULT_ACCESS_TEST_ADMIN, <<-EOC ].join
test "should not allow access to something for Group 1 member" do
user = incline_users(:basic)
group = Incline::AccessGroup.find_or_create_by(name: "Group 1")
user.groups << group
log_in_as user
path = foo_path
get(path)
assert_redirected_to main_app.root_path
end
test "should not allow access to something for Group 2 member" do
user = incline_users(:basic)
group = Incline::AccessGroup.find_or_create_by(name: "Group 2")
user.groups << group
log_in_as user
path = foo_path
get(path)
assert_redirected_to main_app.root_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', deny_groups: [ 'Group 1', 'Group 2' ]
    assert_equal valid, code
  end

  test 'access_tests_for respects success value' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, DEFAULT_ACCESS_TEST_ANY, <<-EOC ].join
test "should allow access to something for admin user" do
user = incline_users(:admin)
log_in_as user
path = foo_path
get(path)
assert_redirected_to bar_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', success: 'bar_path'
    assert_equal valid, code
  end

  test 'access_tests_for respects failure value' do
    valid = [ DEFAULT_ACCESS_TEST_ANON, <<-EOC, DEFAULT_ACCESS_TEST_ADMIN ].join
test "should not allow access to something for any user" do
user = incline_users(:basic)
log_in_as user
path = foo_path
get(path)
assert_redirected_to bar_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', failure: 'bar_path'
    assert_equal valid, code
  end

  test 'access_tests_for respects anon_failure value' do
    valid = [ <<-EOC, DEFAULT_ACCESS_TEST_ANY, DEFAULT_ACCESS_TEST_ADMIN ].join
test "should not allow access to something for anonymous" do
path = foo_path
get(path)
assert_redirected_to bar_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', anon_failure: 'bar_path'
    assert_equal valid, code
  end

  test 'access_tests_for respects method value' do
    valid = <<-EOC
test "should not allow access to something for anonymous" do
path = foo_path
delete(path)
assert_redirected_to incline.login_path
end
test "should not allow access to something for any user" do
user = incline_users(:basic)
log_in_as user
path = foo_path
delete(path)
assert_redirected_to main_app.root_path
end
test "should allow access to something for admin user" do
user = incline_users(:admin)
log_in_as user
path = foo_path
delete(path)
assert_redirected_to foobars_path
end
    EOC

    code = self.class.access_tests_for :something, return_code: true, controller: 'foobar', url_helper: 'foo_path', method: 'delete'
    assert_equal valid, code
  end

  test 'access_tests_for guesses at url_helper correctly' do
    original = <<-EOC
test "should not allow access to index for anonymous" do
path = foobars_path
get(path)
assert_redirected_to incline.login_path
end
test "should not allow access to index for any user" do
user = incline_users(:basic)
log_in_as user
path = foobars_path
get(path)
assert_redirected_to main_app.root_path
end
test "should allow access to index for admin user" do
user = incline_users(:admin)
log_in_as user
path = foobars_path
get(path)
assert_response :success
end
    EOC

    # index
    code = self.class.access_tests_for :index, return_code: true, controller: 'foobar'
    assert_equal original, code

    # show
    valid = original
                .gsub('access to index', 'access to show')
                .gsub('path = foobars_path', 'path = foobar_path(foobars(:one))')
    code = self.class.access_tests_for :show, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # edit
    valid = original
                .gsub('access to index', 'access to edit')
                .gsub('path = foobars_path', 'path = edit_foobar_path(foobars(:one))')
    code = self.class.access_tests_for :edit, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # update
    valid = original
                .gsub('access to index', 'access to update')
                .gsub('path = foobars_path', 'path = foobar_path(foobars(:one))')
                .gsub('get(path)', 'patch(path)')
                .gsub('assert_response :success', 'assert_redirected_to foobars_path')
    code = self.class.access_tests_for :update, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # new
    valid = original
                .gsub('access to index', 'access to new')
                .gsub('path = foobars_path', 'path = new_foobar_path')
    code = self.class.access_tests_for :new, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # create
    valid = original
                .gsub('access to index', 'access to create')
                .gsub('get(path)', 'post(path)')
                .gsub('assert_response :success', 'assert_redirected_to foobars_path')
    code = self.class.access_tests_for :create, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # destroy
    valid = original
                .gsub('access to index', 'access to destroy')
                .gsub('path = foobars_path', 'path = foobar_path(foobars(:one))')
                .gsub('get(path)', 'delete(path)')
                .gsub('assert_response :success', 'assert_redirected_to foobars_path')
    code = self.class.access_tests_for :destroy, return_code: true, controller: 'foobar'
    assert_equal valid, code

    # index + show
    valid = original +
        original
            .gsub('access to index', 'access to show')
            .gsub('path = foobars_path', 'path = foobar_path(foobars(:one))')
    code = self.class.access_tests_for [ :index, :show ], return_code: true, controller: 'foobar'
    assert_equal valid, code

    # the actions can be specified as an explicit array or as additional parameters.
    # as long as the options are specified last, it will work.
    code = self.class.access_tests_for :index, :show, return_code: true, controller: 'foobar'
    assert_equal valid, code
  end

  test 'access_tests_for respects the fixture_helper value for guessed url_helpers' do
    code = self.class.access_tests_for :show, return_code: true, controller: 'foobar', fixture_helper: 'foobazzes'
    assert_equal <<-EOC, code
test "should not allow access to show for anonymous" do
path = foobar_path(foobazzes(:one))
get(path)
assert_redirected_to incline.login_path
end
test "should not allow access to show for any user" do
user = incline_users(:basic)
log_in_as user
path = foobar_path(foobazzes(:one))
get(path)
assert_redirected_to main_app.root_path
end
test "should allow access to show for admin user" do
user = incline_users(:admin)
log_in_as user
path = foobar_path(foobazzes(:one))
get(path)
assert_response :success
end
    EOC
  end

  test 'access_tests_for respects the fixture_key value for guessed url_helpers' do
    code = self.class.access_tests_for :show, return_code: true, controller: 'foobar', fixture_key: :forty_two
    assert_equal <<-EOC, code
test "should not allow access to show for anonymous" do
path = foobar_path(foobars(:forty_two))
get(path)
assert_redirected_to incline.login_path
end
test "should not allow access to show for any user" do
user = incline_users(:basic)
log_in_as user
path = foobar_path(foobars(:forty_two))
get(path)
assert_redirected_to main_app.root_path
end
test "should allow access to show for admin user" do
user = incline_users(:admin)
log_in_as user
path = foobar_path(foobars(:forty_two))
get(path)
assert_response :success
end
    EOC
  end



end