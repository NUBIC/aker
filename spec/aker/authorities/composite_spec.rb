require File.expand_path('../../../spec_helper', __FILE__)

module Aker::Authorities
  describe Composite do
    def actual(*auths, &block)
      conf = Aker::Configuration.new

      conf.logger = spec_logger
      conf.enhance(&block) if block

      Composite.new(conf).tap do |c|
        c.authorities = auths unless auths.empty?
      end
    end

    def actual_log
      @log_io.string
    end

    before do
      @user = Aker::User.new("jo")

      @a = Object.new
      @b = Object.new
      @c = Object.new
      @comp = actual(@a, @b, @c)
    end

    describe "initialization" do
      it "accepts a configuration instance" do
        lambda { Composite.new(Aker::Configuration.new) }.should_not raise_error
      end
    end

    describe "#authorities" do
      it "uses the authorities from the configuration" do
        actual { authorities Object.new, Object.new }.authorities.size.should == 2
      end

      it "prefers directly set authorities" do
        comp = actual { authorities :static }
        comp.authorities = [Static.new.tap { |s| s.valid_credentials!(:user, "foo", "bar") }]

        comp.authorities.size.should == 1
        comp.authorities.first.valid_credentials?(:user, "foo", "bar").should be_true
      end
    end

    describe "#valid_credentials?" do
      it "fails if none of the authorities implement valid_credentials?" do
        expected = /No authentication-providing authority is configured./
        lambda { @comp.valid_credentials?(:magic, 'foo') }.should raise_error expected
      end

      def implement_on(authority, with_user)
        (class << authority; self; end).class_eval do
          define_method(:valid_credentials?) do |kind, *credentials|
            with_user
          end
        end
      end

      it "returns the first user returned by any authority" do
        implement_on(@a, nil)
        implement_on(@b, Aker::User.new("b"))
        implement_on(@c, Aker::User.new("c"))

        @comp.valid_credentials?(:magic, "man").username.should == "b"
      end

      it "returns nil if none of the authorities return a user" do
        implement_on(@a, nil)
        implement_on(@b, :unsupported)

        @comp.valid_credentials?(:magic, "man").should be_nil
      end

      it "returns nil if all the authorities return :unsupported" do
        implement_on(@a, :unsupported)
        implement_on(@b, :unsupported)

        @comp.valid_credentials?(:magic, "man").should be_nil
      end

      it "returns false if any of the authorities returns false" do
        implement_on(@a, @user)
        implement_on(@b, false)

        @comp.valid_credentials?(:magic, "man").should == false
      end

      it "returns false if any of the authorities veto" do
        implement_on(@b, @user)
        def @c.veto?(user); true; end

        @comp.valid_credentials?(:magic, "man").should == false
      end

      it "amplifies the returned user" do
        implement_on(@c, @user)
        def @a.amplify!(user); user.identifiers[:personnel_id] = 17; user; end

        @comp.valid_credentials?(:magic, "man").identifiers[:personnel_id].should == 17
      end

      describe "callbacks" do
        describe "on_authentication_success" do
          before do
            args = {}
            (class << @b; self; end).class_eval do
              define_method(:on_authentication_success) do |user, kind, credentials, authority|
                args.merge!(:user => user, :credentials => credentials,
                            :kind => kind, :authority => authority)
              end
            end
            @args = args
          end

          describe "when successful" do
            before do
              implement_on(@a, @user)
              @comp.valid_credentials?(:user, "jo", "pirate")
            end

            it "receives the right user" do
              @args[:user].should == @user
            end

            it "receives the right kind" do
              @args[:kind].should == :user
            end

            it "receives the right credentials" do
              @args[:credentials].should == ["jo", "pirate"]
            end

            it "receives the right authority" do
              @args[:authority].should == @a
            end

            it "logs an appropriate message" do
              actual_log.should =~ /User "jo" was successfully authenticated by Object./
            end
          end

          it "is not invoked on failure" do
            implement_on(@c, nil)
            @comp.valid_credentials?(:user, "jo", "pirate")
            @args.should be_empty
          end
        end

        describe "on_authentication_failure" do
          before do
            args = {}
            (class << @b; self; end).class_eval do
              define_method(:on_authentication_failure) do |user, kind, credentials, reason|
                args.merge!(:user => user, :credentials => credentials,
                            :kind => kind, :reason => reason)
              end
            end
            @args = args
          end

          it "is not invoked on success" do
            implement_on(@b, @user)
            @comp.valid_credentials?(:user, "jo", "pirate")
            @args.should be_empty
          end

          describe "on failure" do
            def validate
              @comp.valid_credentials?(:user, "jo", "piraat")
            end

            before do
              implement_on(@a, nil)
              implement_on(@b, :unsupported)
              validate
            end

            it "receives the right kind" do
              @args[:kind].should == :user
            end

            it "receives the right credentials" do
              @args[:credentials].should == ["jo", "piraat"]
            end

            describe "because of bad creds" do
              it "receives the right message" do
                @args[:reason].should == "invalid credentials"
              end

              it "receives no user" do
                @args[:user].should be_nil
              end

              it "logs an appropriate message" do
                actual_log.should =~ /Authentication attempt failed: invalid credentials./
              end
            end

            describe "because the kind is not supported" do
              before do
                implement_on(@a, :unsupported)
                validate
              end

              it "receives the right reason" do
                @args[:reason].should == "no configured authorities support :user credentials"
              end

              it "receives no user" do
                @args[:user].should be_nil
              end

              it "logs an appropriate message" do
                actual_log.should =~ /Authentication attempt failed: no configured authorities support :user credentials./
              end
            end

            describe "because of a valid_credentials? veto" do
              before do
                implement_on(@a, false)
                implement_on(@b, @user)
                implement_on(@c, false)
                def @a.to_s; "A"; end
                def @c.to_s; "C"; end
                validate
              end

              it "receives the right reason" do
                @args[:reason].should == "credentials vetoed by A, C"
              end

              it "receives the user" do
                @args[:user].should == @user
              end

              it "logs an appropriate message" do
                actual_log.should =~ /Authentication attempt by "jo" failed: credentials vetoed by A, C./
              end
            end

            describe "because of a veto? veto" do
              before do
                implement_on(@c, @user)
                def @a.veto?(user); true; end
                def @b.veto?(user); true; end
                def @a.to_s; "A"; end
                def @b.to_s; "B"; end
                validate
              end

              it "receives the right reason" do
                @args[:reason].should == "user vetoed by A, B"
              end

              it "receives the user" do
                @args[:user].should == @user
              end
            end
          end
        end
      end
    end

    describe "#veto?" do
      it "returns false if none of the authorities implement veto?" do
        @comp.veto?(@user).should be_false
      end

      it "returns false if all the implementors return falsy values" do
        def @a.veto?(u); false; end
        def @b.veto?(u); nil; end

        @comp.veto?(@user).should be_false
      end

      it "returns true if one of the authorities returns true" do
        def @a.veto?(u); true; end
        def @b.veto?(u); false; end

        @comp.veto?(@user).should be_true
      end
    end

    describe "#on_authentication_success" do
      it "doesn't cause an error if none of the authorities implement it" do
        lambda { @comp.on_authentication_success(Aker::User.new("dc"), :dc, [:dc], :dc) }.
          should_not raise_error
      end

      def implement_on(auth)
        captured_args = {}
        (class << auth; self; end).class_eval do
          define_method(:on_authentication_success) do |user, kind, credentials, authority|
            captured_args.merge!(:user => user, :credentials => credentials,
                                 :kind => kind, :authority => authority)
          end
        end
        captured_args
      end

      describe "invocation" do
        before do
          @a_args = implement_on(@a)
          @b_args = implement_on(@b)
          @comp.on_authentication_success(@user, :magic, ["frob"], @a)
        end

        { "A" => :@a_args, "B" => :@b_args }.each_pair do |name, arg_var|
          describe "on #{name}" do
            before do
              @args = instance_variable_get(arg_var)
            end

            it "passes on the user" do
              @args[:user].username.should == @user.username
            end

            it "passes on the credential kind" do
              @args[:kind].should == :magic
            end

            it "passes on the credentials" do
              @args[:credentials].should == ["frob"]
            end

            it "passes on the authority" do
              @args[:authority].object_id.should == @a.object_id
            end
          end
        end
      end
    end

    describe "#on_authentication_failure" do
      it "doesn't cause an error if none of the authorities implement it" do
        lambda { @comp.on_authentication_failure(Aker::User.new("dc"), :dc, [:dc], :dc) }.
          should_not raise_error
      end

      def implement_on(auth)
        captured_args = {}
        (class << auth; self; end).class_eval do
          define_method(:on_authentication_failure) do |user, kind, credentials, reason|
            captured_args.merge!(:user => user, :credentials => credentials,
                                 :kind => kind, :reason => reason)
          end
        end
        captured_args
      end

      describe "invocation" do
        before do
          @a_args = implement_on(@a)
          @b_args = implement_on(@b)
          @comp.on_authentication_failure(@user, :magic, ["frob"], "A said no")
        end

        { "A" => :@a_args, "B" => :@b_args }.each_pair do |name, arg_var|
          describe "on #{name}" do
            before do
              @args = instance_variable_get(arg_var)
            end

            it "passes on the user" do
              @args[:user].username.should == @user.username
            end

            it "passes on the credential kind" do
              @args[:kind].should == :magic
            end

            it "passes on the credentials" do
              @args[:credentials].should == ["frob"]
            end

            it "passes on the authority" do
              @args[:reason].should == "A said no"
            end
          end
        end
      end
    end

    describe "#amplify!" do
      it "adds the default portal from the configuration if there is one" do
        actual { portal :ENU; authority :static }.amplify!(@user)
        @user.default_portal.should == :ENU
      end

      it "does not cause an error if the configuration doesn't have a portal" do
        lambda { actual(@a).amplify!(@user) }.should_not raise_error
      end

      it "doesn't cause an error if none of the authorities implement it" do
        lambda { @comp.amplify!(@user) }.should_not raise_error
      end

      it "returns the same user that was passed in" do
        @comp.amplify!(@user).object_id.should == @user.object_id
      end

      it "passes the user to all the authorities" do
        def @a.amplify!(user); user.last_name = "Miller"; user; end
        def @b.amplify!(user); user.first_name = "Jo"; user; end

        @comp.amplify!(@user)

        @user.first_name.should == "Jo"
        @user.last_name.should == "Miller"
      end

      it "passes the user to all the authorities in order" do
        def @a.amplify!(user); user.city = "Chicago" unless user.city; user; end
        def @b.amplify!(user); user.city = "Evanston" unless user.city; user; end

        @comp.amplify!(@user).city.should == "Chicago"
      end
    end

    describe "#find_users" do
      it "returns an empty array if none of the authorities implement find_users" do
        @comp.find_users("wak").should == []
      end

      it "aggregates distinct users into a single response array" do
        def @a.find_users(*options); [ Aker::User.new("fred") ]; end
        def @c.find_users(*options); [ Aker::User.new("katherine") ]; end

        @comp.find_users(:something => "foo").
          collect { |u| u.username }.should == %w(fred katherine)
      end

      it "merges users with the same username in authority order" do
        def @a.find_users(options)
          [ Aker::User.new('jo').tap { |u| u.first_name = 'Jo'; u.city = 'Chicago'; },
            Aker::User.new('alice') ]
        end
        def @b.find_users(options)
          [ Aker::User.new('jo').tap { |u| u.last_name = 'Mueller'; u.city = 'Evanston'; },
            Aker::User.new('betty') ]
        end

        actual = @comp.find_users('jo')
        actual.size.should == 3
        actual.collect { |u| u.username }.should == %w(jo alice betty)
        actual.first.full_name.should == "Jo Mueller"
        actual.first.city.should == "Chicago"
      end

      it "rejects nil authority responses" do
        def @a.find_users(*options); [ nil ]; end
        def @c.find_users(*options); nil; end

        @comp.find_users(:etc => 'alia').should == []
      end

      it "splats the arguments given to the authorities" do
        def @a.find_users(*options); @options = options; []; end
        def @a.actual_options; @options; end

        @comp.find_users(:email => 'baz')
        @a.actual_options.should == [{ :email => 'baz' }]
      end

      it "amplifies found users" do
        def @a.find_users(*options); [ Aker::User.new('jo') ]; end
        def @a.amplify!(user); user.last_name = "Miller"; user; end
        def @b.amplify!(user); user.first_name = "Jo"; user; end

        actual = @comp.find_users('jo')
        actual.size.should == 1
        actual.first.full_name.should == "Jo Miller"
      end
    end

    describe "#find_user" do
      # behavior is tested in the module spec
      it "exists" do
        @comp.should respond_to(:find_user)
      end
    end
  end
end
