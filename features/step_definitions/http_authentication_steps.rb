Given /^I am using no credentials$/ do
  header "Authorization", nil
end

Given /I am using the basic credentials "([^\"]*)" \/ "([^\"]*)"$/ do |username, password|
  header "Authorization", "Basic #{["#{username}:#{password}"].pack("m*")})"
end
