begin
  # Go slower in CI
  time_multiplier = (ENV['CI_RUBY'] ? 8 : 1)

  When /^I wait (\d+) seconds$/ do |duration|
    sleep duration.to_i * time_multiplier
  end

  Given /^the application has a session timeout of (\d+) seconds$/ do |timeout|
    Aker.configuration.
      add_parameters_for(:policy, %s(session-timeout-seconds) => (timeout.to_i * time_multiplier))

    restart_spawned_servers
  end
end
