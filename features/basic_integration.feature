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
                        :url => '/avatar_views/:id?style=:style'
      validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/
      """
    And I run a "scaffold" generator to generate a "AvatarView" scaffold with ""
    Given I replace /^  def show$.*?^  end$/ with this snippet in the "avatar_views" controller:
      """
        def show
          style = params[:style] ? params[:style] : 'original'
          record = User.find(params[:id])
          raise 'Error' unless record.avatar.exists?(style)
          send_data record.avatar.file_contents(style),
                      :filename => record.avatar_file_name,
                      :type => record.avatar_content_type
        end
      """
    Given I replace /before_action :set_avatar_view.*?$/ with this snippet in the "avatar_views" controller:
      """
      """

    And I run a "paperclip_database:migration" generator to create storage for paperclip "avatar" to the "User" model
    And I run a migration
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "spec/fixtures/5k.png" to "Avatar"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/avatar_views/1"
    And the file at "/avatar_views/1" should be the same as "spec/fixtures/5k.png"
