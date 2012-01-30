Feature: Rails integration

  Background:
    Given I generate a new rails application
    And I run a rails generator to generate a "User" scaffold with "name:string"
    And I run a paperclip generator to add a paperclip "attachment" to the "User" model
    And I run a migration
    And I update my new user view to include the file upload field
    And I update my user view to include the attachment

  Scenario: Database integration test
    Given I add this snippet to the User model:
      """
      has_attached_file :attachment,
                        :storage => :database,
                        :database_table => :user_attachments,
      """
    And I run a paperclip_database generator to create storage for paperclip "attachment" to the "User" model
    And I run a migration
    And I start the rails application
    When I go to the new user page
    And I fill in "Name" with "something"
    And I attach the file "test/fixtures/5k.png" to "Attachment"
    And I press "Submit"
    Then I should see "Name: something"
    And I should see an image with a path of "/system/attachments/1/original/5k.png"
#    And the table "attachments" should contain 3 rows.
    And the result of "User.first.attachment.file_for(:original).file_contents" should be the same as "test/fixtures/5k.png"

