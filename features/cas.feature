@cas @no_jruby @no_19
Feature: CAS UI authentication

Background:
  Given I have a CAS server that accepts these usernames and passwords:
    | username | password |
    | mr296    | br0wn    |
  And I have a bcsec-protected application using
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
