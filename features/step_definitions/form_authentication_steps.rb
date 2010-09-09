When /^I go to the login form$/ do
  get '/login'
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

Then /^I should see "([^\"]*)" in the "([^\"]*)" field$/ do |text, field|
  form = page.forms.first
  form.field_with(:name => field).value.should == text
end
