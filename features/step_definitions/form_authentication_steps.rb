When /^I go to the login form$/ do
  get '/login'
end

When /^I go to the custom login form$/ do
  get '/custom/login'
  Then 'I should be sent to the custom login page'
end

When /^I go to the custom logout page$/ do
  get '/custom/logout'
end

When /^(?:when )?I enter username "([^\"]*)" and password "([^\"]*)"$/ do |username, password|
  form = page.forms.first
  form.username = username
  form.password = password
  submit form, form.button_with(:value => 'Log in')
end

Then /^I should be sent to the login page$/ do
  (page/'input[name="username"]').should_not be_empty
  (page/'input[name="password"]').should_not be_empty
end

Then /^I should be sent to the custom login page$/ do
  page.uri.to_s.should =~ %r{/custom/login}
  page.body.should include("your secret word")
end

Then /^I should see "([^\"]*)" in the "([^\"]*)" field$/ do |text, field|
  form = page.forms.first
  form.field_with(:name => field).value.should == text
end
