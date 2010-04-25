@cas
Feature: CAS UI authentication

Background:
  Given I have a CAS server that accepts these usernames and passwords:
    | username | password |
    | mr296    | br0wn    |
  And I have a bcsec-protected application using
    | ui_mode |
    | cas     |

Scenario: A user can access a protected resource when already logged into CAS
  Given I have logged into CAS using "mr296" / "br0wn"
    And I am using the UI
   When I access a protected resource
   Then I should be able to access that protected resource

Scenario: A user is prompted to log in when requesting a protected resource and may immediately access the resource after logging in
  Given I am not logged into CAS
    And I am using the UI
   When I access a protected resource
   Then I should be on the CAS login page
   When I submit the form with:
     | username | password |
     | mr296    | br0wn    |
   Then I should be able to access that protected resource
