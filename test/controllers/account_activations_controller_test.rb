require "test_helper"

class AccountActivationsControllerTest < ActionDispatch::IntegrationTest

  def setup
    ActionMailer::Base.deliveries.clear
    # new_user
    @user1 = users(:hanako)
    @user1.new_email = @user1.email
    @user1.email = nil
    @user1.activated = false
    @user1.save
    # change-email-user
    @user2 = users(:tarou)
    @user2.new_email = "new_email@example.com"
    @user2.save
  end

  # should get test
  test "should get email_authentication for new_user" do
    get email_authentication_path(email: @user1.new_email)
    assert_template "account_activations/email_authentication"
    assert_response :success
  end

  test "should get email_authentication for change-email-user" do
    get email_authentication_path(email: @user2.new_email)
    assert_template "account_activations/email_authentication"
    assert_response :success
  end

  test "should get send_email_again for new_user" do
    get send_email_again_path(email: @user1.new_email)
    assert_redirected_to email_authentication_path(email: @user1.email)
    follow_redirect!
    assert_template "account_activations/email_authentication"
  end

  test "should get send_email_again for change-email-user" do
    get send_email_again_path(email: @user2.new_email)
    assert_redirected_to email_authentication_path(email: @user2.email)
    follow_redirect!
    assert_template "account_activations/email_authentication"
  end

  # before_action test
  test "before_action: get_user(without email)" do
    get email_authentication_path(email: "")
    assert flash[:dangerous]
    assert_redirected_to posts_path
    follow_redirect!
    assert_template "posts/index"
  end

  test "before_action: exist_user(activated-user)" do
    @user2.new_email = nil
    get email_authentication_path(email: @user2.email)
    assert flash[:notice]
    assert_redirected_to login_path
    follow_redirect!
    assert_template "users/login"
  end

  test "before_action: exist_user(activated-login-user)" do
    @user2.new_email = nil
    login(@user2)
    get email_authentication_path(email: @user2.email)
    assert flash[:notice]
    assert_redirected_to posts_path
    follow_redirect!
    assert_template "posts/index"
  end

  test "before_action: exist_user(not-activated-user having email" do
    @user2.new_email = nil
    @user2.activated = false
    get email_authentication_path(email: @user2.email)
    assert flash[:dangerous]
    assert_redirected_to posts_path
    follow_redirect!
    assert_template "posts/index"
  end

  test "before_action: correct_user(new-user)" do
    @user1 = users(:hanako)
    @user2 = users(:tarou)
    @user2.new_email = "new2@example.com"
    @user2.save
    login(@user1)
    get email_authentication_path(email: @user2.new_email)
    assert flash[:dangerous]
    assert_redirected_to posts_path
    follow_redirect!
    assert_template "posts/index"
  end

  test "before_action: correct_user("

  # each action test
  test "successful send_email_again" do
    get send_email_again_path(email: @user1.new_email)
    assert_equal 1, ActionMailer::Base.deliveries.size
    assert flash[:notice]
    assert_template "user_mailer/account_activation"
    assert_redirected_to "/email_authentication?email=#{CGI.escape(@user1.new_email)}"
    follow_redirect!
    assert_template "account_activations/email_authentication"
    assert_response :success
  end

  test "successful account_activation(edit) for user(update email)" do
    @user2.activation_digest = BCrypt::Password.create("test")
    login(@user2)
    get edit_account_activation_path("test", email: @user2.new_email)
    assert flash[:dangerous].nil?, flash[:dangerous]
    assert flash[:notice]
    assert_redirected_to posts_path
    follow_redirect!
    assert_template "posts/index"
    assert_response :success
  end

  test "successful account_activation(edit) for user(new)" do
    @user1.activation_digest = BCrypt::Password.create("test")
    get edit_account_activation_path("test", email: @user1.new_email)
    assert_not @user1.activated?
    assert_not @user1[:activated_at].nil?
    assert_not flash[:notice].nil?
    assert_redirected_to login_path
    follow_redirect!
    assert_template "users/login_form"
    assert_response :success
  end

  test "unsuccessful account_activaion(edit) with invalid token" do
    @user1.activation_digest = BCrypt::Password.create("test")
    get edit_account_activation_path("invalid", email: @user1.new_email)
    assert_not flash[:dangerous].nil?
    assert_redirected_to send_email_again_path(email: @user1.new_email)
  end
end
