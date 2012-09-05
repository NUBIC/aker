require File.expand_path('../../../spec_helper', __FILE__)

require 'ladle'

module Aker::Ldap
  describe Authority do
    before(:all) do
      # Create server once; it will be started by specs or groups that
      # need it.
      @server = Ladle::Server.new(
        :quiet => true,
        :allow_anonymous => false,
        :ldif => File.expand_path("../ldap-users.ldif", __FILE__),
        :domain => "dc=northwestern,dc=edu",
        :port => 3897 + port_offset,
        :timeout => ENV['CI_RUBY'] ? 90 : 15 # the CI server is slow sometimes
      )
    end

    after(:all) do
      @server.stop if @server
    end

    # Minimal valid set
    let(:params) {
      {
        :server => '127.0.0.1',
        :search_domain => 'dc=northwestern,dc=edu'
      }
    }

    def actual
      # creates an instance which could connect to the ladle-provided server
      Authority.new({
          # TODO: why doesn't the ladle-provided instance work in
          # anonymous mode?
          :user => 'uid=rms,ou=People,dc=northwestern,dc=edu',
          :password => 'rhett',
          :use_tls => false,
          :port => @server.port
        }.merge(params))
    end

    it "can be instantiated with a Aker::Configuration" do
      p = params
      Authority.new(Aker::Configuration.new { ldap_parameters p }).
        server.should == "127.0.0.1"
    end

    it 'uses a specified name to find its parameters' do
      p = params
      Authority.new(Aker::Configuration.new { foo_parameters p }, :foo).
        server.should == "127.0.0.1"
    end

    it "can be instantiated with a parameters hash" do
      Authority.new(params).server.should == "127.0.0.1"
    end

    describe "at-construction parameter validation" do
      it "requires the server name" do
        params[:server] = nil
        lambda { actual }.should raise_error("The server parameter is required for ldap.")
      end

      it 'requires the search domain' do
        params[:search_domain] = nil
        lambda { actual }.should raise_error('The search_domain parameter is required for ldap.')
      end

      it "does not require a user name" do
        params[:user] = nil
        params[:password] = nil
        lambda { actual }.should_not raise_error
      end

      it "does not require a password usually" do
        params[:user] = nil
        params[:password] = nil
        lambda { actual }.should_not raise_error
      end

      it "requires a password if there is a username" do
        params[:user] = 'uid=rms'
        params[:password] = nil
        lambda { actual }.should raise_error(
          "For ldap, both user and password are required if one is set.")
      end

      it "does not require a port" do
        params[:port] = nil
        actual.port.should == 636
      end
    end

    describe "#server" do
      it "will be set from the :server parameter" do
        actual.server.should == '127.0.0.1'
      end
    end

    describe "Net::LDAP parameter set" do
      before do
        params[:user] = "uid=rms,ou=People,dc=northwestern,dc=edu"
        params[:password] = "rhett"
      end

      it "uses the specified server" do
        actual.ldap_parameters[:host].should == "127.0.0.1"
      end

      it "uses the specified port" do
        params[:port] = 23443
        actual.ldap_parameters[:port].should == 23443
      end

      it "uses the provided username" do
        actual.ldap_parameters[:auth][:username].
          should == "uid=rms,ou=People,dc=northwestern,dc=edu"
      end

      it "uses the provided password" do
        actual.ldap_parameters[:auth][:password].should == "rhett"
      end

      it "uses the simple auth method when authentication is required" do
        actual.ldap_parameters[:auth][:method].should == :simple
      end

      it 'uses anonymous auth when there are no connection credentials' do
        params[:user] = nil
        params[:password] = nil
        actual.ldap_parameters[:auth][:method].should == :anonymous
      end

      it "uses TLS encryption by default" do
        Authority.new(params).ldap_parameters[:encryption].should == :simple_tls
      end

      it "uses no encryption when so configured" do
        params[:use_tls] = false
        actual.ldap_parameters[:encryption].should be_nil
      end
    end

    describe "#attribute_map" do
      subject { Authority.new(params).attribute_map }

      it 'has defaults' do
        subject[:givenname].should == :first_name
      end

      it 'accepts overrides in the configuration' do
        params[:attribute_map] = { :givenname => nil }
        subject[:givenname].should be_nil
      end

      it 'accepts extensions in the configuration' do
        params[:attribute_map] = { :hat_size => :title }
        subject[:hat_size].should == :title
      end
    end

    describe "#attribute_processors" do
      subject { Authority.new(params).attribute_processors }
      let(:user) { Aker::User.new('fred') }

      def process(processor, entry)
        processor.call(user, entry, lambda { |k| [*entry[k]].first })
      end

      describe 'a mapping processor' do
        it 'exists' do
          process(subject[:givenname], { :givenname => ['Fred'] })
          user.first_name.should == 'Fred'
        end

        it 'works when no value is present' do
          process(subject[:givenname], {})
          user.first_name.should be_nil
        end
      end

      it 'accepts overrides in the configuration' do
        params[:attribute_processors] = {
          :givenname => lambda { |user, entry, s| user.first_name = s[:givenname] * 2 }
        }
        process(subject[:givenname], { :givenname => ['Fred'] })
        user.first_name.should == 'FredFred'
      end

      it 'accepts extensions in the configuration' do
        params[:attribute_processors] = {
          :ssn => lambda { |user, entry, s| user.identifiers[:ssn] = s[:ssn] }
        }
        process(subject[:ssn], { :ssn => ['123-08'] })
        user.identifiers[:ssn].should == '123-08'
      end
    end

    describe "a created user object" do
      before do
        @server.start
        @user = actual.find_user('wakibbe')
      end

      it "has a username" do
        @user.username.should == "wakibbe"
      end

      it "has a first name" do
        @user.first_name.should == "Warren"
      end

      it "has a last name" do
        @user.last_name.should == "Kibbe"
      end

      it "has a title" do
        @user.title.should == "Research Associate Professor"
      end

      it "has a business phone" do
        @user.business_phone.should == "+1 312 555 3229"
      end

      it "has a fax" do
        actual.find_user('cbrinson').fax.should == "+1 847 555 0540"
      end

      it "has an e-mail address" do
        @user.email.should == "wakibbe@northwestern.edu"
      end

      it 'uses custom mappings' do
        params[:attribute_map] = { :employeenumber => :country }
        actual.find_user('blc').country.should == '107'
      end

      it 'uses custom processors' do
        params[:attribute_processors] = {
          :addressprocessero => lambda { |user, entry, s|
            user.address = s[:postaladdress].split('$').first
            user.city = s[:postaladdress].split('$').last
          }
        }
        actual.find_user('blc').address.should == 'RUBLOFF 750 N Lake Shore Dr'
        actual.find_user('blc').city.should == 'CH'
      end

      it 'uses no deprecated methods' do
        deprecation_message.should be_nil
      end

      describe "#ldap_attributes" do
        it "has all values for multivalued attributes" do
          @user.ldap_attributes[:ou].should == [
            "NU Clinical and Translational Sciences Institute, Feinberg School of Medicine",
            "Center for Genetic Medicine, Feinberg School of Medicine",
            "People"
          ]
        end

        it "uses downcased keys" do
          @user.ldap_attributes[:givenname].should == ['Warren']
        end
      end

      # ruby-net-ldap strings are weird and can't be serialized.
      it "is serializable" do
        ser = Marshal.dump(@user)
        Marshal.load(ser).username.should == 'wakibbe'
      end
    end

    # Net::LDAP::Filter isn't very testable
    describe "#find_users" do
      def found_usernames(*criteria)
        @server.start
        actual.find_users(*criteria).collect { |u| u.username }.sort
      end

      it "returns nothing for no criteria" do
        found_usernames().should == []
      end

      describe "with a string" do
        it "filters by username" do
          found_usernames('wakibbe').should == %w(wakibbe)
        end
      end

      describe "with Aker::User attributes" do
        it "filters by username" do
          found_usernames(:username => 'sbw').should == %w(sbw)
        end

        it "filters by first name" do
          found_usernames(:first_name => 'Rhett').should == %w(rms)
        end

        it "filters by last name" do
          found_usernames(:last_name => "Garcia").should == %w(ega)
        end

        it "filters by title" do
          found_usernames(:title => 'Research Associate Professor').
            should == %w(wakibbe)
        end

        it "filters by e-mail address" do
          found_usernames(:email => 'b-chamberlain@northwestern.edu').
            should == %w(blc)
        end

        it "filters by phone number" do
          found_usernames(:business_phone => '+1 312 555 2324').should == %w(rms)
        end

        it "filters by fax" do
          found_usernames(:fax => '+1 847 555 0540').should == %w(cbrinson)
        end

        it 'filters using a custom attribute mapping' do
          params[:attribute_map] = { :displayname => :country }
          found_usernames(:country => 'Warren A Kibbe').should == %w(wakibbe)
        end
      end

      describe 'with explicitly mapped criteria attributes' do
        it 'works' do
          params[:criteria_map] = { :emplid => :employeenumber }
          found_usernames(:emplid => '105').should == %w(rms)
        end

        it 'prefers the mapping that is explicitly for criteria' do
          params[:criteria_map] = { :title => :employeenumber }
          params[:attribute_map] = { :displayname => :title }
          found_usernames(:title => '107').should == %w(blc)
        end
      end

      describe "with other attributes" do
        it "ignores them when they are in combination with known attributes" do
          found_usernames(:username => 'rms', :frob => 'pulse').should == %w(rms)
        end

        it "returns nothing when they are alone" do
          found_usernames(:frob => 'pulse').should == []
        end
      end

      describe "with nil values" do
        it "ignore those keys when in combination with non-nil values" do
          found_usernames(:username => nil, :first_name => 'Sean').
            should == %w(sbw)
        end

        it "returns nothing if they are alone" do
          found_usernames(:title => nil).should == []
        end
      end

      it "requires that all criteria match" do
        found_usernames(:first_name => 'Warren', :last_name => 'Kibbe').
          should == %w(wakibbe)
        found_usernames(:first_name => 'L Catherine', :last_name => 'Kibbe').
          should == []
      end

      describe "with multiple disjoint criteria" do
        it "understands multiple usernames" do
          found_usernames('wakibbe', 'cbrinson', 'stl667').should == %w(cbrinson wakibbe)
        end

        it "ORs multiples sets of criteria" do
          found_usernames({ :first_name => 'L Catherine' }, { :last_name => 'Kibbe'}).
            should == %w(cbrinson wakibbe)
        end

        it "handles a mix of hashes and usernames" do
          found_usernames(
            { :first_name => 'Brian' }, { :first_name => 'Sean' }, 'ega', 'sbw').
            should == %w(blc ega sbw)
        end
      end
    end

    describe "credential validation" do
      def login(username, password)
        @server.start
        actual.valid_credentials?(:user, username, password)
      end

      describe "when authentic" do
        it "is not nil" do
          login('wakibbe', 'warren').should_not be_nil
        end

        it "is filled out" do
          login('rms', 'rhett').last_name.should == 'Sutphin'
        end
      end

      it "is not valid for an unknown user" do
        login('jp', 'foo').should be_nil
      end

      it "is not valid when not authentic" do
        login('wakibbe', 'ekib').should be_nil
      end

      it "is not valid with a blank password" do
        login('wakibbe', '').should be_nil
      end

      it "only handles :user credentials" do
        actual.valid_credentials?(:retina_scan, 1701).should == :unsupported
      end
    end

    describe "#amplify!" do
      before do
        @server.start
        @user = Aker::User.new('wakibbe')
      end

      def amplified
        actual.amplify!(@user)
      end

      it "does nothing for an unknown user" do
        lambda { actual.amplify!(Aker::User.new("joe")) }.should_not raise_error
      end

      describe "on a blank instance" do
        it "copies simple attributes" do
          amplified.first_name.should == "Warren"
        end

        it "has a last name" do
          amplified.last_name.should == "Kibbe"
        end

        it "has a title" do
          amplified.title.should == "Research Associate Professor"
        end

        it "has a business phone" do
          amplified.business_phone.should == "+1 312 555 3229"
        end
      end
    end
  end
end
