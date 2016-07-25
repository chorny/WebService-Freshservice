package WebService::Freshservice::Test;

use strict;
use warnings;
use WebService::Freshservice::API;
use Method::Signatures;
use Test::Most;
use Moo;
use namespace::autoclean;

has 'config' => (
  is => 'ro',
  lazy => 1,
  builder => 1,
);

method _build_config() {
  use Config::Tiny;
  my $config = Config::Tiny->read( "$ENV{HOME}/.freshservicetest" );
  return $config;
}

method test_with_auth($test, $number_tests) {
  SKIP: {
    skip "Live testing not implemented.", $number_tests;
    #skip "No auth credentials found.", $number_tests unless ( -e "$ENV{HOME}/.freshervicetest" );

    eval {  
      require Config::Tiny;
    };

    skip 'These tests are for online testing and require Config::Tiny.', $number_tests if ($@);

    my $api = WebService::Freshservice::API->new(
      apikey => $self->config->{auth}{key}, 
      apiurl => $self->config->{auth}{url}, 
    );

    $test->($api,"Testing Live Freshservice API");
  }
}

method test_with_dancer($test, $number_tests) {
  SKIP: {
    eval {  
      require Dancer2; 
      require Scalar::Util;
    };

    skip 'These tests are for cached testing and require Dancer2 + Scalar::Util.', $number_tests if ($@);

    my $pid = fork();

    if (!$pid) {
      exec("t/bin/cached_api.pl");
    }

    # Allow some time for the instance to spawn. TODO: Make this smarter
    sleep 5;

    my $api = WebService::Freshservice::API->new(
      apikey => 'aReallyGoodone..', 
      apiurl => "http://localhost:3001",
    );

    $test->($api, "Testing Cached Freshservice API");
  
    # Kill Dancer
    kill 9, $pid;
  }
}

1;
