Aker History
============

3.0.4
-----

- Fixed: Documentation for `Aker::Cas::ServiceMode` referenced 
  incorrect parameter names.

3.0.3
-----
- Added: search_domain configuration option to LDAP authority. (#15)
  This new option is mandatory; the lack of this option in prior
  versions of the authority meant that they would not work with LDAP
  servers other than Northwestern's.

3.0.2
-----
- Added missing LICENSE file. Aker is made available under the MIT
  license. (#9)
- Fixed: `Aker::Cas::Middleware::TicketRemover` now sets its response's
  Content-Type.  `TicketRemover` also now returns a link to the cleaned URI,
  following recommendations set forth in RFC 2616.  (#10)
- Added: `Aker::User#permit?` accepts an `:affiliate_ids` option. (#11)

3.0.1
-----
- Fixed: with AS3, using `active_support/core_ext` requires the i18n
  gem, so add a dependency on it (#5).

3.0.0
-----
- First open-source version.
- Project renamed from "Bcsec" (short for Bioinformatics Core
  security) to "Aker" (ancient Egyptian god of the horizon).
- Bcsec contained several authorities which were specific to NUBIC;
  those have been removed and purged from the git history for the
  project.
- Added :custom_form mode (#1).

Bcsec History
=============

This is the history for the parts of Bcsec which remain in
Aker. Versions that only included changes to code which has been
removed from the open source version have been removed.

2.2.0
-----
- Introduced the concept of "configuration slices" so that extensions
  may add default configuration values. (#5875)
- Introduced mode registration and authority aliases so that named
  modes and authorities can have arbitrary class names. (#5875)
- Introduced the ability to configure rack middleware to be installed
  relative to bcsec (outside of modes). (#5875)
- Bcsec now has a 30 minute session timeout.  (#5156)
- It is now possible to customize the login and logout pages when using the
  `form` mode.  (#5469)
- Added a generic LDAP authority. (#5876)
- Send a permanent redirect after a successful CAS authentication in
  order to prevent the service ticket from showing up in the user's
  browsing history. (#2725)
- Extract and expose the method for determining the CAS service URL
  for a particular request. (See `Bcsec::Cas::ServiceUrl`.)
- Updated JRuby tested version to 1.6.2.

2.1.0
-----

- ActiveRecord / ActiveSupport 3 compatibility. (#2804)
- Fixed: user information is no longer saved in the session in
  non-interactive modes.  (#2757)

2.0.5
-----

- Updated tested platforms to JRuby 1.5.3 and Ruby 1.9.2.  (MRI 1.8.7
  in the specific form of REE 2010.02 remains the same.)

2.0.4
-----

- Changed: the #find_users method on the authorities interface now
  accepts one or more separate criteria.  The separate criteria are
  joined using a logical OR.  All the built-in authorities have been
  updated to support this; custom authorities may need to be updated
  as well.  (#4027)
- Added: `Bcsec::Authorities::Static#load!` will now load arbitrary
  `Bcsec::User` attributes from the YAML file, not just the username,
  password, and authorization information. (#4297)
- Changed: Depend on net-ldap 0.1.1 instead of ruby-net-ldap 0.0.4.
  This new version of the net/ldap library is backwards compatible,
  interface-wise, but it trades 1.8.6- support for 1.9+ support.

2.0.3
-----

- Fixed: static authority now allows different users to have the same
  password. (#4068)

2.0.1
-----

- Added `Bcsec::Authorities::AutomaticAccess`.

2.0.0
-----

- Complete rewrite: better architecture (no sole singletons); rack
  support; better RESTful API authentication support; support for MRI
  1.8.7, JRuby, and YARV 1.9.1; and much more.

1.6.1
-----

- Correct MockAuthenticator-authorized users so that they reflect the
  appropriate group memberships when logging in with CAS (bug #2221)
- Prevent nil dereference in User#in_group? when the user has no groups at all

1.6.0
-----

- Fix nil-sensitivity bug in Bcsec.use_cas (#1994)
- Remove explicit `gem` invocations from library code
- Make minor changes to allow bcsec to run under jruby 1.4.0

1.5.2
-----

- Modify build layout a bit so that the source directory can be used with
  bundler's :path option in sowsear

1.5.0
-----

- Update to use open source versions of bcdatabase and
  schema_qualified_tables.

1.4.8
-----

- Configuration from use_cas now propagates to RailsCasFilter.

1.4.0
-----

- Allow CAS configuration parameters to be passed to use_cas.
  These parameters are passed directly to CASClient::Client; see
  http://rubycas-client.rubyforge.org/ for configuration details.
  These parameters override central configuration.

1.3.0
-----

- Dev: support deploy:tag from git-svn clones

1.2.6
-----

- Added Bcsec::AuthenticateOnlyAuthenticator for when you only need to
  authenticate. It responds to allow_access? and always returns true.
- Added ability to add authenticators with may_access? method only.
- Added rspec-rails version to use when running specs.

1.2.2
-----

- Correct _dependency_ definitions in gemspec.  (Was using _requirements_,
  which are informational only.)  `gem install bcsec` will now install all
  dependent gems.

1.2.1
-----

- Clear the effects of use_cas in Bcsec::Configurator#clear

1.2.0
-----

- Add Bcsec::portal_set? and similar to allow querying whether certain
  config attributes are set without throwing an exception when they aren't.
- Add adapter code in rspec_helper.rb so that rspec-rails can be used as a gem.

1.1.0
-----

- Added publicly-accessible method Bcsec#amplify! to provide bcsec consumers
  with the ability to manually invoke group data retrieval.

1.0.1
-----

- Fix issue when having multiple authenticors and the first one returns no groups

1.0.0
-----

- A user's security groups are cached in the current user object in the
  session.
- In group checks are handled in memory instead of hitting the database every
  time.
- Added dependency on RubyTree gem

0.1.1
-----

- Fix issue where Bcsec::CentralAuthenticationParameters would sometimes not be
  automatically resolved by applications using ActiveSupport's dependency
  loader.

0.1.0
-----

- Add CAS support
- Add MockAuthenticator#load_credentials! to support loading test credentials
  from a file.

0.0.2
-----

- Adapt deploy task to be multi-developer friendly
- Add separate uninstall task to return to published version

0.0.1
-----

- Fix rake tasks for deploy, local install
- Integrate ci_reporter
- Add rudimentary environment support in order to build in hudson
- Made site affiliate portal foreign key explicit

0.0.0
-----

- Extract non-rails-specific bcsec elements from bcsec engine.
- Convert test/unit tests moved from bcsec plugin into rspec specs.  (Shallow
  conversion only so far.)
