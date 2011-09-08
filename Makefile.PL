use strict;
use warnings;

use inc::Module::Install;

name 'Test-Mock-Guard';
all_from 'lib/Test/Mock/Guard.pm';

requires 'Exporter' => 5.63;
requires 'Class::Load' => 0.06;

tests 't/*.t';
author_tests 'xt';

test_requires 'Test::More' => 0.96;
auto_set_repository;
auto_include;
WriteAll;
