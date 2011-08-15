@cas @no_jruby
Feature: CAS UI authentication

  Background:
    Given I have a CAS server that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have an aker-protected application using
      | ui_mode | authority |
      | cas     | cas       |

  Scenario: A user can access a protected resource when already logged into CAS
    Given I have logged into CAS using "mr296" / "br0wn"
     When I access a protected resource
     Then I should be able to access that protected resource

  Scenario: A user is prompted to log in when requesting a protected resource and is immediately sent to the resource after logging in
    Given I am not logged into CAS
     When I access a protected resource
     Then I should be on the CAS login page
     When I fill out the form with:
       | username | password |
       | mr296    | br0wn    |
      And I click "LOGIN"
     Then I should be able to access that protected resource

  Scenario: The CAS login process preserves queries on protected resources
    Given I am not logged into CAS
    When I access a search resource
    Then I should be on the CAS login page
    When I fill out the form with:
       | username | password |
       | mr296    | br0wn    |
    And I click "LOGIN"

    Then I should see the search results

  Scenario: The CAS login process removes the service ticket on successful login
    Given I am not logged into CAS
     When I access a protected resource
     Then I should be on the CAS login page
     When I fill out the form with:
       | username | password |
       | mr296    | br0wn    |
      And I click "LOGIN"

     Then I should be able to access that protected resource
      And the current URL should not contain a service ticket

  Scenario: Logging out of an application means the user can no longer access protected resources
    Given I have logged into CAS using "mr296" / "br0wn"

    When I log out of the application
    And I access a protected resource

    Then I should be on the CAS login page

  Scenario: Logging out of an application redirects the user to the CAS server's logout URL
    Given I have logged into CAS using "mr296" / "br0wn"

    When I log out of the application

    Then I should be on the CAS logout page

  Scenario: Session timeouts do not interfere with single sign on
    Given I have logged into CAS using "mr296" / "br0wn"
    And the application has a session timeout of 2 seconds

    When I access a protected resource
    And I wait 4 seconds
    And I access a protected resource

    Then I should be able to access that protected resource
