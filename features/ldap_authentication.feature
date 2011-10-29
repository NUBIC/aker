@ldap @no_jruby
Feature: LDAP authentication
  In order to protect confidential data
  Users of aker-protected applications
  must log in to use said applications.

  This feature tests LDAP-backed authentication.

  Background:
    Given I have a ldap authority
    And I have an aker-protected application using
      | ui_mode | api_modes |
      | form    |           |

  Scenario: A correct username and password passes authentication
    When I go to the login form
    And I enter username "ee855" and password "nosreme"
    And I access a protected resource
    Then I should be able to access that protected resource

  Scenario: An incorrect password fails authentication
    When I go to the login form
    And I enter username "ee855" and password "noswad"
    Then I should see "Login failed" on the page
