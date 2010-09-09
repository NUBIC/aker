Feature: Access control
  In order to specify what users may see
  Bcsec-protected applications
  must be able to specify access levels for different resources

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password  |
      | mr296    | br0wn     |
      | zaw102   | squidward |
    And mr296 is in the Owners and Command groups for Serenity
    And zaw102 is in the Command group for Serenity
    And I have a bcsec-protected application using
      | api_modes  | portal   |
      | http_basic | Serenity |
    And I am using the API

  Scenario: A user can access a group-protected resource for a group he is in
    Given I am using the basic credentials "mr296" / "br0wn"
    When I access an owners-only resource
    Then I should be able to access that owners-only resource

  Scenario: A user cannot access a group-protected resource for a group she is not in
    Given I am using the basic credentials "zaw102" / "squidward"
    When I access an owners-only resource
    Then access is forbidden

  Scenario: An anonymous user cannot access a group-protected resource
    Given I am using no credentials
    When I access an owners-only resource
    Then I should be prompted to log in

  Scenario: A user can see special content based on his group
    Given I am using the basic credentials "mr296" / "br0wn"
    When I access a group-sensitive resource
    Then I should see the owners' content for that group-sensitive resource

  Scenario: A user does not see special content for a group she's not in
    Given I am using the basic credentials "zaw102" / "squidward"
    When I access a group-sensitive resource
    Then I should see the general content for that group-sensitive resource

  Scenario: An anonymous user does not see special content
    Given I am using no credentials
    When I access a group-sensitive resource
    Then I should see the general content for that group-sensitive resource
