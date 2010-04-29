Then /^I should see "([^\"]*)" on the page$/ do |content|
  page.should have_content(content)
end

When /^I fill out the form with:$/ do |table|
  table.hashes.each do |hash|
    hash.keys.each do |field|
      fill_in field, :with => hash[field]
    end
  end
end

When /^I click "([^\"]*)"$/ do |button_name|
  click_button button_name
end
