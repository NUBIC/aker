@wip
Feature: Form authentication
  In order to protect confidential data
  Users of bcsec-protected applications
  must log in to use said applications.

  This feature tests form-based authentication.

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | abc123   | foobar   |
    And I have a bcsec-protected application using
      | ui mode | api mode |
      | form    |          |

  Scenario: A correct username and password should pass authentication
    When I enter username "abc123" and password "foobar" into the login form
    And I access a protected resource

    Then I should be able to access that protected resource

  Scenario: Users accessing protected resources without authentication should be sent to the login page
    When I access a protected resource

    Then I should be sent to the login page

  Scenario: Users failing authentication should be sent to the login page
    When I enter username "abc123" and password "wrong" into the login form

    Then I should be sent to the login page
