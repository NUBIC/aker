When "I am using the API" do
  header "Accept", "application/json"
  agent.redirect_ok = false # capture redirects
  agent.user_agent = "MyApiConsumer/#{Bcsec::VERSION}"
end

When /^I access an? (\S+) resource$/ do |resource_kind|
  url =
    case resource_kind
    when "protected"
      "/protected"
    when "search"
      "/search?q=something&format=json"
    when "owners-only"
      "/owners"
    when "group-sensitive"
      "/shared"
    when "API-using"
      "/consume"
    when "replaying"
      "/replaying"
    else
      pending "No URL defined for #{resource_kind.inspect}"
    end

  get url
end

When /^I access an? (\S+) resource without supplying credentials$/ do |resource_kind|
  Given "I am using no credentials"
  When "I access a #{resource_kind} resource"
end

When /^I do concurrent requests on an API\-using resource$/ do
  # Because truly concurrent requests
  #
  # (1) have nondeterministic behavior, which is bad for tests
  # (2) would be very difficult to properly support with our test framework
  #
  # we simulate concurrent requests by sending two requests with the same
  # session data, as a real browser would do.
  #
  # First, we get all of our CAS tickets straightened out by making a request
  # to a CAS-protected call that doesn't do CAS proxying.
  get "/protected"
  page.body.should =~ /I'm protected/

  @responses = []

  # Next, we capture the session state for reuse.
  session = agent.cookies.find { |c| c.domain == 'localhost' && c.name == 'rack.session' }.value
  session.should_not be_nil

  # Next, we make our first request.
  get "/consume"
  @responses << page.body

  # To simulate a second, concurrent request, we reset the cookie jar to the
  # way it was prior to the first request.
  agent.cookie_jar.jar['localhost']['/']['rack.session'].value = session

  # Finally, we issue the second request.
  get "/consume"
  @responses << page.body
end

Then /^I should be able to access that (\S+) resource$/ do |resource_kind|
  pattern =
    case resource_kind
    when "protected"
      /I'm protected/
    when "owners-only"
      /Only owners can see this page at all./
    else
      pending "No pattern defined for #{resource_kind.inspect}"
    end

  page.code.should == "200"
  page.body.should =~ pattern
end

Then /^I should see the search results$/ do
  page.body.should == 'Format: json, results: something'
end

When /^I log out of the application$/ do
  get "/logout"
end

Then /^I should see the (\S+) content for that group\-sensitive resource$/ do |which|
  Then "the HTTP status should be 200"
  sensitive = /there is special content for Owners/
  if which =~ /owner/i
    page.body.should =~ sensitive
  else
    page.body.should_not =~ sensitive
  end
end

Then /^the page contains the results of the API call$/ do
  page.body.should =~ /The API said: I'm protected/
end

Then /^the page should not contain the results of the API call$/ do
  page.body.should_not =~ /The API said: I'm protected/
end

Then /^each response should contain the results of the API call$/ do
  @responses.should all_match(/The API said: I'm protected/)
end

Then /the HTTP status should be (\d{3})/ do |status|
  page.code.should == status
end

Then /^the '([^']*)' header should be '([^']*)'$/ do |header, expected|
  page.header[header].should == expected
end

Then /^the '([^']*)' header should include '([^']*)'$/ do |header, expected|
  page.header[header].should =~ Regexp.new(expected)
end

Then /^access is forbidden$/ do
  Then "the HTTP status should be 403"
  page.body.should =~ /may not use this page./
  page.header["Content-Type"].should == "text/html"
end

# assumes a pure-HTTP mode
Then /^I should be prompted to log in$/ do
  Then "the HTTP status should be 401"
end
