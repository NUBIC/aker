Then /^I should see "([^\"]*)" on the page$/ do |content|
  page.should have_content(content)
end
