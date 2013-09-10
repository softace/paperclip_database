Feature: Rails integration

  Background:
    Given I generate a new rails application
    And I run a "scaffold" generator to generate a "User" scaffold with "name:string"
    And I run a "paperclip" generator to add a paperclip "attachment" to the "User" model
    And I run a migration
    And I update my new user view to include the file upload field
    And I update my user view to include the attachment
    And I allow the attachment to be submitted

  Scenario: Database integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :attachment,
                        :storage => :database,
                        :database_table => :user_attachments,
                        :url => '/user_attachment_views/:id?style=:style'
      """
    And I run a "scaffold" generator to generate a "UserAttachmentView" scaffold with ""
    Given I add this snippet to the "user_attachment_views" controller:
      """
        def show
          style = params[:style] ? params[:style] : 'original'
          record = User.find(params[:id])
          send_data record.attachment.file_contents(style),
                      :filename => record.attachment_file_name,
                      :type => record.attachment_content_type
        end
      """
    And I run a "paperclip_database:migration" generator to create storage for paperclip "attachment" to the "User" model
    And I run a migration
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Attachment"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/user_attachment_views/1?style=original"
    And the file at "/user_attachment_views/1?style=original" should be the same as "test/fixtures/5k.png"

