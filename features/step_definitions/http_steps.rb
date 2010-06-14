When "I am using the API" do
  header "Accept", "application/json"
  @using_rack_test = true
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
    else
      pending "No URL defined for #{resource_kind.inspect}"
    end

  if @using_rack_test
    get url
  else
    visit url
  end
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
  visit "/protected"
  page.source.should =~ /I'm protected/

  @responses = []

  # Next, we capture the session state for reuse.
  browser = Capybara.current_session.driver.browser
  session = browser.cookies['localhost']['rack.session']

  # Next, we make our first request.
  visit("/consume")
  @responses << page.source

  # To simulate a second, concurrent request, we reset the cookie jar to the
  # way it was prior to the first request.
  browser.add_cookie('localhost', 'rack.session', session)

  # Finally, we issue the second request.
  visit("/consume")
  @responses << page.source
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

  if @using_rack_test
    last_response.status.should == 200
    last_response.body.should =~ pattern
  else
    page.source.should =~ pattern
  end
end

Then /^I should see the search results$/ do
  page.source.should == 'Format: json, results: something'
end

When /^I log out of the application$/ do
  if @using_rack_test
    get "/logout"
  else
    visit "/logout"
  end
end

Then /^I should see the (\S+) content for that group\-sensitive resource$/ do |which|
  sensitive = /there is special content for Owners/
  if which =~ /owner/i
    last_response.body.should =~ sensitive
  else
    last_response.body.should_not =~ sensitive
  end
end

Then /^the page contains the results of the API call$/ do
  page.source.should =~ /The API said: I'm protected/
end

Then /^each response should contain the results of the API call$/ do
  @responses.all? do |response|
    response.should =~ /The API said: I'm protected/
  end.should be_true
end

Then /the HTTP status should be (\d{3})/ do |status|
  last_response.status.should == status.to_i
end

Then /^the '([^']*)' header should be '([^']*)'$/ do |header, expected|
  last_response.headers[header].should == expected
end

Then /^the '([^']*)' header should include '([^']*)'$/ do |header, expected|
  last_response.headers[header].should =~ Regexp.new(expected)
end

Then /^access is forbidden$/ do
  Then "the HTTP status should be 403"
  last_response.body.should =~ /may not use this page./
  last_response.headers["Content-Type"].should == "text/html"
end

# assumes a pure-HTTP mode
Then /^I should be prompted to log in$/ do
  Then "the HTTP status should be 401"
end
