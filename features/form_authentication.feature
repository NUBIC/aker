@capybara
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
      | ui_mode | api_modes | portal   |
      | form    |           | Serenity |

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
