Aker
====

Aker is a library for managing authentication and authorization in
ruby applications (particularly Rack applications). It is designed to
extensibly work with your existing (possibly legacy) authentication
infrastructure.

Aker is made up of **authorities** which provide user security
information, **modes** which integrate authentication with HTTP (via
Rack), and a **configuration** which specifies which of these to use
and how to set them up.

Aker concepts
-------------

### Authorities

An **authority** in Aker is the encapsulation of a mechanism for
providing authentication and/or authorization.  The methods which an
authority may implement (all are optional) are described in detail in
the documentation for the {Aker::Authorities::Composite composite
authority}.  All the included authorities are described in the
documentation for the {Aker::Authorities} module.  See their
documentation for more information.

More than one authority can be used in a particular configuration.
When validating credentials or performing any of the other actions
provided by the authority interface, all the authorities will be
consulted.  The documentation for the composite authority describes
how the results are aggregated for each action.

### Modes

An Aker **mode** is a mechanism for receiving credentials in the context
of a web application.  Aker modes come in variants that are intended
for use in human-user-facing contexts (*UI* modes) and machine-facing
contexts (*API* modes).  It is possible for the same mode to act in
both capacities.

An application may have zero-to-many API modes, but only one UI mode.
API modes work within a standard [RFC2617][] HTTP Authorization
interface, while UI modes have broad access to the Rack environment to
prompt the user as necessary.

All the included modes are described in the documentation of the
{Aker::Modes} module. See their documentation for more information.
If you would like to implement your own mode, see {Aker::Modes::Base}.

#### API vs. UI

Aker uses the following heuristic to determine whether to attempt to
authenticate a particular request using the configured UI mode or API
mode(s):

* If there are no API modes configured, requests are always handled by
  the UI mode.
* If the HTTP Accept header includes `text/html` (literally includes
  it, not matches it), the request is handled by the UI mode.
* If the HTTP User-Agent header includes `Mozilla`, the request is
  handled by the UI mode.
* Otherwise, the request is handled by the API mode(s).

[RFC2617]: http://www.ietf.org/rfc/rfc2617.txt

### Configuration

The aker **configuration** is where you define the authorities and
modes (and their parameters) for your application.  It's a class whose
instances can be initialized both {Aker::Configuration traditionally}
and using a {Aker::ConfiguratorLanguage DSL}.  There's a global
instance ({Aker.configuration}) which will be sufficient for most
uses and which can be updated using the DSL via {Aker.configure}.

Since {Aker.configure} updates the configuration (rather than
replacing it), it is worthwhile to consider splitting up your
configuration into environment-specific and common parts.  For
instance, you might have the common configuration:

    Aker.configure {
      ui_mode :form
      api_mode :http_basic
    }

And then for your development environment use:

    Aker.configure {
      authority Aker::Authorities::Static.from_file("#{Rails.root}/environments/development-users.yml")
      central "/etc/nubic/aker-local.yml"
    }

And in your tests use:

    Aker.configure {
      authority Aker::Authorities::Static.from_file("#{Rails.root}/spec/test-users.yml")
    }

But then in production use:

    Aker.configure {
      authorities :ldap
      central "/etc/nubic/aker-prod.yml"
    }

Using form authentication
-------------------------

Aker's {Aker::Form::Mode :form} mode provides a traditional HTML
form for user authentication.  It works with one or more authorities
which handle the `:user` credential kind &mdash; compatible
authorities that ship with Aker are {Aker::Ldap::Authority
:ldap}, and {Aker::Authorities::Static :static}.

`:form` is the default UI mode.  If you want to explicitly configure
it, do like so:

    Aker.configure {
      authorities :static # whatever is appropriate for your app
      ui_mode :form
    }

Using CAS
---------

Aker's {Aker::Cas::ServiceMode :cas} mode provides interactive user
authentication via an external CAS 2 server.  The
{Aker::Cas::ProxyMode :cas_proxy} mode complements `:cas` by providing
non-interactive authentication using CAS proxy tickets.  Each of these
modes works with an authority which can handle the corresponding
credential kind (i.e., `:cas` needs a `:cas`-handling authority). The
{Aker::Cas::Authority :cas} authority handles both.  Here's an
example configuration:

    Aker.configure {
      authority :cas
      ui_mode :cas
      api_mode :cas_proxy # don't include unless needed
    }

(The `:static` authority can also verify `:cas` and `:cas_proxy`
credentials, but it is relatively awkward to set up and so is left as
an exercise for the adventurous integrated tester.)

Since the CAS server provides authentication only, you may also want
to configure an authority to provide authorization information.

Authenticating a RESTful API
----------------------------

As noted above, Aker has specific support for [RFC2617][]-style
standard HTTP authentication.  It supports multiple simultaneous API
authentication modes.  The most common case for multiple API modes
will be CAS-protected APIs which also need to provide non-interactive
API access (e.g., for cron jobs, since they are not run in the context
of a user logged into any particular application).  Here's a sample
configuration:

    Aker.configure {
      ui_mode :cas
      api_mode :http_basic, :cas_proxy

      authorities :cas, :ldap

      central "/etc/nubic/aker-local.yml"
    }

In this case, the CAS server will be used for interactive logins and
for CAS proxy ticket validation, while HTTP Basic-authenticated
requests will be validated using the `:ldap` authority.

Rack (and Rails) integration
----------------------------

Aker's web application integration is based on [Rack][].  This means
it can be used with nearly any ruby web framework, including Sinatra,
Camping, etc., in addition to Rails.

In your Aker-protected Rack application, you have access to a
`"aker.check"` key in the Rack environment.  This key will yield an
instance of {Aker::Rack::Facade} which provides methods for
determining who is logged in, checking permissions, requiring
authentication, etc.  See its API documentation for more information.

To configure Aker into your Rack application, use
{Aker::Rack.use_in}.  See that method's API documentation for more
information.

#### Rails

While Rack support is built into the main Aker gem, Rails support (for
both Rails 2.3 and 3.x) is in a separate gem plugin.  See the README
in the [`aker-rails` gem][aker-rails] for more information about it.

[Rack]: http://rack.rubyforge.org/
[aker-rails]: https://github.com/NUBIC/aker-rails

Aker outside of a Rack app
--------------------------

Aker's authorities are independent of its HTTP integration, so they
may be used in any ruby script or application.  Here's an example:

    #!/usr/bin/env ruby

    require 'rubygems'
    require 'aker'

    Aker.configure {
      authorities :ldap, :static
      central "/etc/nubic/aker-staging.yml"
    }

    u = Aker.authority.valid_credentials?(:user, 'wakibbe', 'ekibder')
        # => valid_credentials? returns a Aker::User on success

    if !u
      $stderr.puts "Bad credentials"
      exit(1)
    elsif u.permit?('Admin')
      lookedup = Aker.authority.find_user(ARGV[0])
      if lookedup
        puts "#{ARGV[0]} is the username of #{lookedup.full_name}"
      else
        puts "#{ARGV[0]} isn't a valid username"
      end
    else
      $stderr.puts "Unauthorized"
      exit(2)
    end

See the rest of the API documentation for more information.

Extending Aker
--------------

Aker was built for extensibility. Here are the highlights; see the
relevant sections above for more.

* {Aker::Authorities::Composite#valid_credentials? Authentication} and
  {Aker::Authorities::Composite#amplify! authorization} can be
  provided by implementing an {Aker::Authorities authority}. An
  application can configure in multiple authorities and their results
  will be intelligently combined. Authorities can also implement
  {Aker::Authorities::Composite#on_authentication_success success} and
  {Aker::Authorities::Composite#on_authentication_failure failure}
  callbacks to provide for auditing or
  {Aker::Authorities::Composite#veto? lockout} features.
* An HTTP-based credential presentation mechanism can be implemented
  as a {Aker::Modes mode}. E.g., you would write a mode to adapt to a
  legacy single-sign-on system.
* Authorities and modes can be customized through
  {Aker::Configuration#parameters_for parameters} included in the
  {Aker::Configuration configuration}.
* Reusable extensions can be packaged as gems and registered alongside
  Aker's built-in functionality. Extensions may use
  {Aker::Configuration::Slice slices} to register themselves, set
  defaults parameter values, and register middleware that will be
  included relative to Aker's own middleware.

Limitations
-----------

Aker's original iteration was a rails plugin built to assist the
Northwestern University Biomedical Informatics Center in transitioning
legacy systems to Ruby on Rails. Since then it's been used in dozens
of applications, both ports of existing systems and ones newly
built.

While it can be adapted to many kinds of applications, it is probably
not a good choice if you are not integrating with an existing
authentication or authorization backend. It does not include any
mechanism for provisioning users or letting users sign up for accounts
on their own. Such things could be built for it, but if that's what
you need then one of the other existing ruby security frameworks might
get you up and running faster.
