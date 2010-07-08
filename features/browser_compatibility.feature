Feature: Browser compatibility
  In order to get NUBIC applications to use bcsec
  The bcsec library
  must work with all browsers we support.

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have a bcsec-protected application using
      | ui_mode | api_modes |
      | form    |           |

  @wip
  Scenario: A user using Internet Explorer 7 can use interactive authentication
    IE7 doesn't state it accepts text/html (or anything like it), which
    eliminates one possibility for determining whether we can use interactive
    authentication.  Other criteria must exist.

    Given I am using Internet Explorer 7

    When I access a protected resource

    Then I should be sent to the login page
