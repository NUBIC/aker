When "I am using the API" do
  header "Accept", "application/json"
end

When "I am using the UI" do
  header "Accept", "text/html"
end

When /^I access a protected resource$/ do
  get "/protected"
end

Then /^I should be able to access that protected resource$/ do
  last_response.status.should == 200
  last_response.body.should =~ /I'm protected/
end

Then /the HTTP status should be (\d{3})/ do |status|
  last_response.status.should == status.to_i
end

Then /^the "([^\"]*)" header should be "([^\"]*)"$/ do |header, expected|
  last_response.headers[header].should == expected
end
