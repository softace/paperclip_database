Feature: Rails integration

  Background:
    Given I generate a new rails application
    And I run a "scaffold" generator to generate a "User" scaffold with "name:string"
    And I run a "paperclip" generator to add a paperclip "avatar" to the "User" model
    And I run a migration
    And I update my new user view to include the file upload field
    And I update my user view to include the attachment
    And I allow the attachment to be submitted

  Scenario: Database integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :avatar,
                        :storage => :database,
                        :database_table => :user_avatars,
                        :url => '/user_avatar_views/:id?style=:style'
      """
    And I run a "scaffold" generator to generate a "UserAvatarView" scaffold with ""
    Given I replace /^  def show$.*?^  end$/ with this snippet in the "user_avatar_views" controller:
      """
        def show
          style = params[:style] ? params[:style] : 'original'
          record = User.find(params[:id])
          send_data record.avatar.file_contents(style),
                      :filename => record.avatar_file_name,
                      :type => record.avatar_content_type
        end
      """
    Given I replace /before_action :set_user_avatar_view.*?$/ with this snippet in the "user_avatar_views" controller:
      """
      """

    And I run a "paperclip_database:migration" generator to create storage for paperclip "avatar" to the "User" model
    And I run a migration
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Avatar"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/user_avatar_views/1?style=original"
    And the file at "/user_avatar_views/1?style=original" should be the same as "test/fixtures/5k.png"

  Scenario: Database integration test with table specification
    Given I add this snippet to the User model:
      """
      has_attached_file :avatar,
                        :storage => :database,
                        :database_table => :pictures,
                        :url => '/user_avatar_views/:id?style=:style'
      """
    And I run a "scaffold" generator to generate a "UserAvatarView" scaffold with ""
    Given I replace /^  def show$.*?^  end$/ with this snippet in the "user_avatar_views" controller:
      """
        def show
          style = params[:style] ? params[:style] : 'original'
          record = User.find(params[:id])
          send_data record.avatar.file_contents(style),
                      :filename => record.avatar_file_name,
                      :type => record.avatar_content_type
        end
      """
    Given I replace /before_action :set_user_avatar_view.*?$/ with this snippet in the "user_avatar_views" controller:
      """
      """
    And I run a "paperclip_database:migration" generator to create storage for paperclip "pictures" to the "User" model
    And I run a migration
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Avatar"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/user_avatar_views/1?style=original"
    And the file at "/user_avatar_views/1?style=original" should be the same as "test/fixtures/5k.png"

