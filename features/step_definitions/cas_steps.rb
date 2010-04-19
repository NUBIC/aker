Given /^I have logged into CAS using "([^\"]*)" \/ "([^\"]*)"$/ do |username, password|
  visit @cas_server.base_url
  fill_in "username", :with => username
  fill_in "password", :with => password
  click_button "LOGIN"
  page.source.should include("You have successfully logged in")
end
