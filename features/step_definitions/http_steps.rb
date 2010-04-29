When "I am using the API" do
  header "Accept", "application/json"
  @using_api = true
end

When /^I access a protected resource$/ do
  if @using_api
    get "/protected"
  else
    visit "/protected"
  end
end

Then /^I should be able to access that protected resource$/ do
  if @using_api
    last_response.status.should == 200
    last_response.body.should =~ /I'm protected/
  else
    page.source.should =~ /I'm protected/
  end
end

Then /the HTTP status should be (\d{3})/ do |status|
  last_response.status.should == status.to_i
end

Then /^the '([^']*)' header should be '([^']*)'$/ do |header, expected|
  last_response.headers[header].should == expected
end
