@no_jruby
Feature: Browser compatibility
  In order to get NUBIC applications to use bcsec
  The bcsec library
  must work with all browsers we support.

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password  |
      | mr296    | br0wn     |
    And I have a bcsec-protected application using
      | ui_mode | api_modes  |
      | form    | http_basic |

  Scenario: A user using Internet Explorer 7 can use interactive authentication
    Given I am using Internet Explorer 7

    When I access a protected resource

    Then I should be sent to the login page
