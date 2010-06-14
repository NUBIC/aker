@cas @no_jruby @no_19
Feature: CAS proxy authentication

  Background:
    Given I have a CAS server that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have a bcsec-protected RESTful API using
      | ui_mode | api_modes | authority |
      | cas     | cas_proxy | cas       |
    And I have a bcsec-protected consumer of a CAS-protected API
    And I have logged into CAS using "mr296" / "br0wn"

  Scenario:
    When I access an API-using resource
    Then the page contains the results of the API call

  Scenario: A user can do concurrent proxied requests
    When I do concurrent requests on an API-using resource

    Then each response should contain the results of the API call
