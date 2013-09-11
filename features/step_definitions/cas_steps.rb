Given /^I have logged into CAS using "([^\"]*)" \/ "([^\"]*)"$/ do |username, password|
  get cas_base_url
  login_form = page.forms.first
  login_form.username =  username
  login_form.password = password
  submit login_form
  page.body.should include("You have successfully logged in")
end

Given /^I have established a CAS session$/ do
  When "I access an API-using resource"
end

Given /^I am not logged into CAS/ do
  get File.join(cas_base_url, "logout")
  page.body.should include("You have successfully logged out")
end

Then /^I should be on the CAS login page$/ do
  login_base = File.join(cas_base_url, "login")
  page.uri.to_s.should =~ %r{^#{login_base}}
end

Then /^I should be on the CAS logout page$/ do
  logout_base = File.join(cas_base_url, "logout")
  page.uri.to_s.should =~ %r{^#{logout_base}}
end

Then /^the current URL should not contain a service ticket$/ do
  page.uri.to_s.should_not =~ %r{ticket=}
end
