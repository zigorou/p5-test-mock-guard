use inc::Module::Install;
name 'Test-Mock-Guard';
all_from 'lib/Test/Mock/Guard.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More';
auto_set_repository;
auto_include;
WriteAll;
