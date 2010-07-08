Given /^I am using Internet Explorer 7$/ do
  # Accept string from:
  #
  # http://blogs.msdn.com/b/ieinternals/archive/2009/07/01/9811694.aspx
  #
  # (we use the simpler of all of IE's forms for Accept)
  #
  # User-Agent string from:
  #
  # http://blogs.msdn.com/b/ie/archive/2006/09/20/763891.aspx
  # http://blogs.msdn.com/b/ie/archive/2005/04/27/412813.aspx
  @using_rack_test = true
  @env = { 'HTTP_ACCEPT' => '*/*',
           'HTTP_USER_AGENT' => 'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1)' }
end
