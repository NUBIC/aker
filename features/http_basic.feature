Feature: HTTP Basic Authentication

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And mr296 is in Serenity
    And I have a bcsec-protected application using
      | ui_mode | api_modes  | portal   |
      |         | http_basic | Serenity |

  Scenario: A user can access a protected resource with the correct credentials
    Given I am using the basic credentials "mr296" / "br0wn"
      And I am using the API
     When I access a protected resource
     Then I should be able to access that protected resource

  Scenario: A request with no credentials is challenged
    Given I am using no credentials
      And I am using the API
     When I access a protected resource
     Then the HTTP status should be 401
      And the 'WWW-Authenticate' header should be 'Basic realm="Serenity"'

  Scenario: A request with incorrect credentials is challenged
    Given I am using the basic credentials "mr296" / "wrong"
      And I am using the API
     When I access a protected resource
     Then the HTTP status should be 401
      And the 'WWW-Authenticate' header should be 'Basic realm="Serenity"'
