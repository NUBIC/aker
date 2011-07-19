@no_jruby
Feature: Form authentication
  In order to protect confidential data
  Users of aker-protected applications
  must log in to use said applications.

  This feature tests form-based authentication.

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have a aker-protected application using
      | ui_mode | api_modes |
      | form    |           |

  Scenario: A correct username and password should pass authentication
    When I go to the login form
    And I enter username "mr296" and password "br0wn"
    And I access a protected resource

    Then I should be able to access that protected resource

  Scenario: Users accessing protected resources without authentication should be sent to the login page
    When I access a protected resource

    Then I should be sent to the login page

  Scenario: Successful login results in redirection to the requested resource
    When I access a protected resource
    Then I should be sent to the login page

    When I enter username "mr296" and password "br0wn"
    Then I should be able to access that protected resource

  Scenario: The requested resource is persisted across failed login attempts
    When I access a protected resource
    Then I should be sent to the login page

    When I enter username "mr296" and password "wrong"
    Then I should be sent to the login page
    But when I enter username "mr296" and password "br0wn"
    Then I should be able to access that protected resource

  Scenario: Users failing authentication should be told their login attempt failed
    When I go to the login form
    And I enter username "mr296" and password "wrong"

    Then I should be sent to the login page
    And I should see "Login failed" on the page

  Scenario: The supplied username is persisted across failed login attempts
    When I go to the login form
    And I enter username "mr296" and password "wrong"

    Then I should be sent to the login page
    And I should see "mr296" in the "username" field

  Scenario: Logging out of an application means the user can no longer access protected resources
    Given I go to the login form
    And I enter username "mr296" and password "br0wn"

    When I log out of the application
    And I access a protected resource

    Then I should be sent to the login page

  Scenario: Logging out of an application shows the login form
    Given I go to the login form
    And I enter username "mr296" and password "br0wn"

    When I log out of the application

    Then I should be sent to the login page
    And I should see "Logged out" on the page

  @wip
  Scenario: Session timeouts are enforced
    Given the application has a session timeout of 2 seconds
    And I go to the login form
    And I enter username "mr296" and password "br0wn"

    When I access a protected resource
    And I wait 4 seconds
    And I access a protected resource

    Then I should be sent to the login page
     And I should see "Session timed out" on the page

  Scenario: Requests made within a session extend the session length
    Given the application has a session timeout of 5 seconds
    And I go to the login form
    And I enter username "mr296" and password "br0wn"

    When I access a protected resource
    And I wait 3 seconds
    And I access a protected resource
    And I wait 3 seconds
    And I access a protected resource

    Then I should be able to access that protected resource
