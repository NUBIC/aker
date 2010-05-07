When "I am using the API" do
  header "Accept", "application/json"
  @using_api = true
end

When /^I access an? (\S+) resource$/ do |resource_kind|
  url =
    case resource_kind
    when "protected"
      "/protected"
    when "owners-only"
      "/owners"
    when "group-sensitive"
      "/shared"
    when "API-using"
      "/consume"
    else
      pending "No URL defined for #{resource_kind.inspect}"
    end

  if @using_api
    get url
  else
    visit url
  end
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

  if @using_api
    last_response.status.should == 200
    last_response.body.should =~ pattern
  else
    page.source.should =~ pattern
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
