Feature: Checking the weather for the next 5 days
  
  Scenario: Successfully checking the weather for the next 5 days
    When user try to check the weather
    Then system should return with the weather for the next 5 days
