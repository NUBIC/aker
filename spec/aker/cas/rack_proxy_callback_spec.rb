require File.expand_path('../../../spec_helper', __FILE__)
require 'rack'
require 'fileutils'

module Aker::Cas
  shared_examples_for "rack proxy callback handler" do
    describe "/receive_pgt" do
      describe "with both a pgtId and pgtIou" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/receive_pgt?pgtId=PGT-baz&pgtIou=PGTIOU-foo")
        end

        it "stores the pair" do
          pstore = PStore.new(@store_filename)
          pstore.transaction do
            pstore["PGTIOU-foo"].should == "PGT-baz"
          end
        end

        it "returns success" do
          @response.status.should == 200
        end

        it "gives a worthwhile message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should =~ /PGT and PGTIOU received./
        end
      end

      describe "without a pgtId" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/receive_pgt?pgtIou=PGTIOU-foo")
        end

        it "is a bad request" do
          @response.status.should == 400
        end

        it "gives a worthwile error message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should ==
            "pgtId is a required query parameter." <<
            "\nSee section 2.5.4 of the CAS protocol specification."
        end
      end

      describe "without a pgtIou" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/receive_pgt?pgtId=PGT-foo")
        end

        it "is a bad request" do
          @response.status.should == 400
        end

        it "gives a worthwile error message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should ==
            "pgtIou is a required query parameter." <<
            "\nSee section 2.5.4 of the CAS protocol specification."
        end
      end

      describe "without either" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/receive_pgt")
        end

        it "is OK, because the JA-SIG CAS server expects it to be" do
          @response.status.should == 200
        end

        it "gives a worthwile error message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should ==
            "Both pgtId and pgtIou are required query parameters." <<
            "\nSee section 2.5.4 of the CAS protocol specification."
        end
      end
    end

    describe "/retrieve_pgt" do
      describe "with a known pgtIou" do
        before do
          pstore = PStore.new(@store_filename)
          pstore.transaction do
            pstore["PGTIOU-678"] = "PGT-876"
          end

          @response = Rack::MockRequest.new(@app).
            get("/retrieve_pgt?pgtIou=PGTIOU-678")
        end

        it "is successful" do
          @response.status.should == 200
        end

        it "returns the PGT" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should == "PGT-876"
        end

        it "deletes the PGT from the store once it has been retrieved" do
          pstore = PStore.new(@store_filename)
          pstore.transaction do
            pstore["PGTIOU-678"].should be_nil
          end
        end
      end

      describe "with an unknown pgtIou" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/retrieve_pgt?pgtIou=PGTIOU-1234")
        end

        it "returns 404" do
          @response.status.should == 404
        end

        it "provides a helpful message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should ==
            "pgtIou=PGTIOU-1234 does not exist.  Perhaps it has already been retrieved."
        end
      end

      describe "without a pgtIou" do
        before do
          @response = Rack::MockRequest.new(@app).
            get("/retrieve_pgt")
        end

        it "is a bad request" do
          @response.status.should == 400
        end

        it "provides a worthwhile error message" do
          @response.headers["Content-Type"].should == "text/plain"
          @response.body.should ==
            "pgtIou is a required query parameter."
        end
      end
    end
  end

  describe RackProxyCallback do
    before do
      @store_filename = "#{tmpdir}/#{File.basename(__FILE__)}.pstore"
    end

    after do
      FileUtils.rm @store_filename if File.exist?(@store_filename)
    end

    describe "as middleware" do
      before do
        endpoint = lambda { |env| [200, {}, ["App invoked"]] }
        @app = RackProxyCallback.new(endpoint, :store => @store_filename)
      end

      it_should_behave_like "rack proxy callback handler"

      it "invokes the app for other paths" do
        Rack::MockRequest.new(@app).get("/foo").should =~ /App invoked/
      end

      it "requires a filename for the store" do
        lambda { RackProxyCallback.new(Object.new) }.
          should raise_error(/Please specify a filename for the PGT store/)
      end
    end

    describe "as an application" do
      before do
        @app = RackProxyCallback.application :store => @store_filename
      end

      it_should_behave_like "rack proxy callback handler"

      it "404s for non-pgt requests" do
        Rack::MockRequest.new(@app).get("/foo").status.should == 404
      end
    end
  end
end
