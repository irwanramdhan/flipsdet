Feature: Submit user information

Scenario: Unsuccessfully submit user information
  Given the user is on user inform page
  When the user leave all the field blank and insert an 'invalid_data'
  Then the system should prevent user to submit the form

Scenario: Successfully submit user information
  Given the user is on user inform page
  When the user fill the field with 'valid_data' and submit form
  Then the system should successfully submitted the form