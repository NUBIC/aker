######
# This is not an executable script.  It selects and configures rvm for
# bcsec's CI process based on the BCSEC_ENV environment variable.
#
# Use it by sourcing it:
#
#  . ci-rvm.sh
#
# Assumes that the create-on-use settings are set in your ~/.rvmrc:
#
#  rvm_install_on_use_flag=1
#  rvm_gemset_create_on_use_flag=1

set +x
echo ". ~/.rvm/scripts/rvm"
. ~/.rvm/scripts/rvm
set -x

unset BCSEC_RVM_RUBY
case "$BCSEC_ENV" in
'ci_1.8.7')
BCSEC_RVM_RUBY='ree-1.8.7-2010.02';
;;
'ci_1.9')
BCSEC_RVM_RUBY='ruby-1.9.2-p0';
;;
'ci_jruby')
BCSEC_RVM_RUBY='jruby-1.5.3';
;;
esac

GEMSET=bcsec

if [ -z "$BCSEC_RVM_RUBY" ]; then
    echo "Could not map env (BCSEC_ENV=\"${BCSEC_ENV}\") to an RVM version.";
    shopt -q login_shell
    if [ $? -eq 0 ]; then
        echo "This means you are still using the previously selected RVM ruby."
        echo "Probably not what you want -- aborting."
        # don't exit an interactive shell
        return;
    else
        exit 1;
    fi
fi

echo "Switching to ${BCSEC_RVM_RUBY}@${GEMSET}"
set +xe
rvm use "${BCSEC_RVM_RUBY}@${GEMSET}"
if [ $? -ne 0 ]; then
    echo "Switch failed"
    exit 2;
fi
set -xe
ruby -v

set +e
gem list -i rake
if [ $? -ne 0 ]; then
    echo "Installing rake since it is not available"
    gem install rake
fi
set -e
