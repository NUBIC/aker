@cas @no_jruby @no_19
Feature: CAS proxy authentication

  Background:
    Given I have a CAS server that accepts these usernames and passwords:
      | username | password |
      | mr296    | br0wn    |
    And I have an aker-protected RESTful API using
      | ui_mode | api_modes | authority |
      | cas     | cas_proxy | cas       |
    And I have an aker-protected consumer of a CAS-protected API
    And I have logged into CAS using "mr296" / "br0wn"

  Scenario:
    When I access an API-using resource
    Then the page contains the results of the API call

  Scenario: A user can do concurrent proxied requests
    When I do concurrent requests on an API-using resource

    Then each response should contain the results of the API call

  Scenario: CAS proxy authentication does not persist user data to the session
    In this scenario, a "replaying resource" refers to a resource that
    surreptituously stores the response it receives from the Web service API it
    invokes, and then re-uses any cookies it receives from that response into
    future requests.

    If a session cookie is present in the response of said API, then
    that resource could impersonate the original user without that user's
    consent.

    Given I have established a CAS session
     When I access a replaying resource
      And I log out of the application
      And I access a replaying resource without supplying credentials
     Then the page should not contain the results of the API call
