use v6;
use Zef::Distribution;
use Zef::Roles::Precompiling;
use Zef::Roles::Processing;
use Zef::Utils::PathTools;
use Test;
plan 1;



# Basic tests on default builder method
subtest {
    my $path    := $?FILE.IO.dirname.IO.parent; # ehhh
    my $save-to := $path.child("test-libs_{time}{100000.rand.Int}").IO;
    my $precomp-path = $save-to.IO.child('lib');

    LEAVE {       # Cleanup
        sleep 1;  # bug-fix for CompUnit related pipe file race
        try rm($save-to, :d, :f, :r);
    }

    my $distribution = Zef::Distribution.new(:$path, :$precomp-path);
    $distribution does Zef::Roles::Precompiling;
    $distribution does Zef::Roles::Processing;

    my @cmds = $distribution.precomp-cmds;

    my @source-files = $distribution.provides(:absolute)\
        .grep({ state %cache; !%cache{$_.key}++ }).hash.values.unique;
    my @target-files = $distribution.provides-precomp(:absolute)\
        .grep({ state %cache; !%cache{$_.key}++ }).hash.values.unique;

    $distribution.queue-processes( [$_.list] ) for @cmds;

    await $distribution.start-processes;

    is $distribution.passes.elems, @source-files.elems, "Found expected precompiled files";
    is $distribution.failures.elems, 0, "No apparent precompilation failures";

    for @target-files -> $file {
        ok $file.IO.e, "Found: {$file.IO.relative($path)}";
    }
}, 'Zef::Builder';



done();
