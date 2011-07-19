@no_jruby
Feature: Form authentication with custom views
  In order to engender user trust
  And not promote confusion
  An application may need to use custom login and logout views

  Background:
    Given I have an authority that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have a aker-protected application using
      | ui_mode     | rack_parameters                                                      |
      | custom_form | { :login_path => '/custom/login', :logout_path => '/custom/logout' } |

  Scenario: A correct username and password should pass authentication
    When I go to the custom login form
    And I enter username "mr296" and password "br0wn"
    And I access a protected resource

    Then I should be able to access that protected resource

  Scenario: Users accessing protected resources without authentication should be sent to the login page
    When I access a protected resource

    Then I should be sent to the custom login page
     And I should see "/protected" on the page

  Scenario: Users failing authentication should be told their login attempt failed
    When I go to the custom login form
    And I enter username "mr296" and password "wrong"

    Then I should be sent to the custom login page
    And I should see "Last login failed" on the page

  Scenario: The supplied username can be persisted across failed login attempts
    When I go to the custom login form
    And I enter username "mr296" and password "wrong"

    Then I should be sent to the custom login page
    And I should see "last time you said mr296" on the page

  Scenario: Logging out of an application means the user can no longer access protected resources
    Given I go to the custom login form
    And I enter username "mr296" and password "br0wn"

    When I go to the custom logout page
    And I access a protected resource

    Then I should be sent to the custom login page

  Scenario: Logging out of an application shows the custom logout page
    Given I go to the custom login form
    And I enter username "mr296" and password "br0wn"

    When I go to the custom logout page

    Then I should see "Thanks for visiting" on the page

  Scenario: Session timeouts are enforced
    Given the application has a session timeout of 2 seconds
    And I go to the custom login form
    And I enter username "mr296" and password "br0wn"

    When I access a protected resource
    And I wait 4 seconds
    And I access a protected resource

    Then I should be sent to the custom login page
     And I should see "You waited too long" on the page
