@no_jruby
Feature: HTTP Basic Authentication for UI

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And mr296 is in Serenity
    And I have a bcsec-protected application using
      | ui_mode    | api_modes | portal   |
      | http_basic |           | Serenity |

  Scenario: A user can access a protected resource in interactive mode
      And I am using the basic credentials "mr296" / "br0wn"
     When I access a protected resource
     Then I should be able to access that protected resource

  Scenario: An interactive request with no credentials is challenged
      And I am using no credentials
     When I access a protected resource
     Then the HTTP status should be 401
     And the 'WWW-Authenticate' header should be 'Basic realm="Serenity"'

  Scenario: An interactive request with incorrect credentials is challenged
      And I am using the basic credentials "mr296" / "wrong"
     When I access a protected resource
     Then the HTTP status should be 401
      And the 'WWW-Authenticate' header should be 'Basic realm="Serenity"'
