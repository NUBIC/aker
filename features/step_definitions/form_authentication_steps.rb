When /^I enter username "([^\"]*)" and password "([^\"]*)" into the login form$/ do |username, password|
  visit '/login'
  fill_in 'Username', :with => username
  fill_in 'Password', :with => password
  click_button 'Log in'
end

Then /^I should be sent to the login page$/ do
  last_response.status.should == 302
  URI.parse(last_response.location).path.should == '/login'
end
