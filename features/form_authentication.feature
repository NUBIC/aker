Feature: Form authentication
  In order to protect confidential data
  Users of bcsec-protected applications
  must log in to use said applications.

  This feature tests form-based authentication.

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have a bcsec-protected application using
      | ui_mode | api_modes |
      | form    |           |

  Scenario: A correct username and password should pass authentication
    When I enter username "mr296" and password "br0wn" into the login form
    And I access a protected resource

    Then I should be able to access that protected resource

  Scenario: Users accessing protected resources without authentication should be sent to the login page
    When I access a protected resource

    Then I should be sent to the login page

  Scenario: Users failing authentication should be told their login attempt failed
    When I enter username "mr296" and password "wrong" into the login form

    Then I should be sent to the login page
    And I should see "Login failed" on the page

  Scenario: The supplied username is persisted across failed login attempts
    When I enter username "mr296" and password "wrong" into the login form

    Then I should be sent to the login page
    And I should see "mr296" in the "username" field

  Scenario: Logging out of an application means the user can no longer access protected resources
    Given I enter username "mr296" and password "br0wn" into the login form

    When I log out of the application
    And I access a protected resource

    Then I should be sent to the login page

  Scenario: Logging out of an application shows the login form
    Given I enter username "mr296" and password "br0wn" into the login form

    When I log out of the application

    Then I should be sent to the login page
    And I should see "Logged out" on the page
