Feature: Multiple API modes
  In order to support disparate clients
  Bcsec-protected APIs
  May need to support multiple authentication mechanisms

Background:
  Given I have an authority that accepts these usernames and passwords:
    | username | password |
    | mr296    | br0wn    |
  And I have a bcsec-protected application using
    | api_modes            | portal   |
    | cas_proxy http_basic | Serenity |
  And I am using the API

Scenario: When unauthenticated, all modes are challenged
  Given I am using no credentials
   When I access a protected resource
   Then the HTTP status should be 401
    And the 'WWW-Authenticate' header should include 'Basic realm="Serenity"'
    And the 'WWW-Authenticate' header should include 'CasProxy realm="Serenity"'

Scenario: Credentials for a single mode are accepted
  Given I am using the basic credentials "mr296" / "br0wn"
   When I access a protected resource
   Then I should be able to access that protected resource
