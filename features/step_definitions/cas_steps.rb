Given /^I have logged into CAS using "([^\"]*)" \/ "([^\"]*)"$/ do |username, password|
  visit @cas_server.base_url
  fill_in "username", :with => username
  fill_in "password", :with => password
  click_button "LOGIN"
  page.source.should include("You have successfully logged in")
end

Given /^I am not logged into CAS/ do
  visit File.join(@cas_server.base_url, "logout")
  page.source.should include("You have successfully logged out")
end

Then /^I should be on the CAS login page$/ do
  login_base = File.join(@cas_server.base_url, "login")
  page.current_url.should =~ %r{^#{login_base}}
end

Then /^I should be on the CAS logout page$/ do
  logout_base = File.join(@cas_server.base_url, "logout")
  page.current_url.should =~ %r{^#{logout_base}}
end
