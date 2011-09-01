use strict;
use warnings;
use Test::More;
use Test::Mock::Guard qw(mock_guard);

{
    note 'empty';
    local $@;
    eval { mock_guard() };
    like $@, qr/must be specified key-value pair/;
}

{
    note 'not pair';
    local $@;
    eval { mock_guard('Foo') };
    like $@, qr/must be specified key-value pai/;
}

{
    note 'module not found';
    local $@;
    eval { mock_guard('__THIS__::__MODULE__::__IS__::__DUMMY__' => {}) };
    like $@, qr/Can't locate __THIS__/;
}

{
    note 'class name undefined';
    local $@;
    eval { mock_guard(undef, {}) };
    like $@, qr/Usage: mock_guard/;
}

{
    note 'method_defs is not hasref';
    local $@;
    eval { mock_guard('Foo::Bar', []) };
    like $@, qr/Usage: mock_guard/;
}

done_testing;
