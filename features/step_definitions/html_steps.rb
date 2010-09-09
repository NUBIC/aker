Then /^I should see "([^\"]*)" on the page$/ do |content|
  page.body.should include(content)
end

When /^I fill out the form with:$/ do |table|
  table.hashes.each do |hash|
    hash.keys.each do |field|
      page.forms.first.field_with(:name => field).value = hash[field]
    end
  end
end

When /^I click "([^\"]*)"$/ do |button_name|
  form = page.forms.first
  submit form, form.button_with(:value => button_name)
end
