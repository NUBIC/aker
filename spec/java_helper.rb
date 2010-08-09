require 'java'

Dir[File.join(File.dirname(__FILE__), '../vendor/java/*.jar')].each do |jar|
  $CLASSPATH << jar
end
