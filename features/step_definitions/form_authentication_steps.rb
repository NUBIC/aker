When /^I go to the login form$/ do
  visit '/login'
end

When /^(?:when )?I enter username "([^\"]*)" and password "([^\"]*)"$/ do |username, password|
  fill_in 'username', :with => username
  fill_in 'password', :with => password
  click_button 'Log in'
end

Then /^I should be sent to the login page$/ do
  page.should have_field('username')
  page.should have_field('password')
end

Then /^I should see "([^\"]*)" in the "([^\"]*)" field$/ do |text, field|
  page.should have_field(field, :with => text)
end
