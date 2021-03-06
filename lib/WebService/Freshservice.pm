package WebService::Freshservice;

use v5.010;
use strict;
use warnings;
use WebService::Freshservice::API;
use Carp qw( croak );
use Method::Signatures 20140224;
use Moo;
use namespace::clean;

# ABSTRACT: Abstraction layer to the Freshservice API

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use WebService::Freshservice;
  
  my $freshservice = WebService::Freshservice->new( apikey => '1234567890abcdef' );

=head1 DESCRIPTION

WebService::Freshservice is an abstraction layer to the Freshservice API.

=cut


has 'apikey'  => ( is => 'ro', required => 1 );
has 'apiurl'  => ( is => 'ro', default => sub { "https://imdexlimited.freshservice.com" } );
has '_api'    => ( is => 'rw', lazy => 1, builder => 1 );

method _build__api {
  return WebService::Freshservice::API->new(
    apikey => $self->apikey,
    apiurl => $self->apiurl,
  );
}

# Agent/User searching is pretty much identical.
# TODO: Pagination is possible using 'page=#'
method _search(
    :$email?,
    :$mobile?,
    :$phone?,
    :$state = 'all',
    :$page?,
  ) {

  # Who ya gunna call? (find the calling method)
  my $caller = substr((caller 1)[3],26);
  my $package = $caller eq "requesters" ? "User" : "Agent";

  # Build query
  my $query = "?";
  if ($email) {
    $query .= "query=email is $email";
  }
  if ($mobile) {
    $query .= "&" unless $query eq "?";
    $query .= "query=mobile is $mobile";
  }
  if ($phone) {
    $query .= "&" unless $query eq "?";
    $query .= "query=phone is $phone";
  }
  my $endpoint = $caller eq 'requesters' ? "itil/requesters.json" : "agents.json";
  $endpoint .= $query unless $query eq "?";
  $endpoint .= $query eq "?" ? "?state=$state" : "&state=$state";
  $endpoint .= "&page=$page" if $page;
  my $users = $self->_api->get_api($endpoint);

  # Build objects
  my @objects;
  if ( 0+@{$users} > 0 ) {
    foreach my $user ( @{$users} ) {
      push(
        @objects, 
        "WebService::Freshservice::$package"->new( 
          api   => $self->_api, 
          id    => $user->{lc($package)}{id}, 
          _raw  => $user,
        ),
      );
    }
  }
   
  return \@objects;
}

# Like the seach method, populating an agent is identical.
method _user( :$id?, :$email? ) {
  # Who ya gunna call? (find the calling method)
  my $caller = substr((caller 1)[3],26);
  my $package = $caller eq "requester" ? "User" : "Agent";
  my $search = $caller."s"; # Our search methods are plurals of singular methods.

  my $user;
  if ($email) {
    my @users = @{$self->$search( email => $email )};
    croak "No $caller found with $email" unless 0+@users > 0;
    $user = $users[0];
  } else {
    croak "'id' or 'email' required." unless $id;
    $user = "WebService::Freshservice::$package"->new( api => $self->_api, id => $id );
  }
  return $user;
}

use WebService::Freshservice::User;

=method requester

  $freshservice->requester( id => '123456789' );

Returns a WebService::Freshservice::User on success, croaks on failure.
Optionally if you can use the attribute 'email' and it will search
returning the first result, croaking if not found.

=cut

method requester(...) {
  return $self->_user(@_);
}

=method requesters

  $freshservice->requesters( email => 'test@example.com');

Perform a search on the provided attribute and optional state. If
no query is set it will return the first 50 results.

Use one the following attributes, 'email', 'mobile' or 'phone'.

Optionally state can be set to one of 'verified', 'unverified',
'all' or 'deleted'. Defaults to 'all'.

Returns an array of 'WebService::Freshservice::User' objects or
empty array if no results are found.

=cut

method requesters(...) {
  return $self->_search(@_);
}

=method create_requester

  $freshservice->create_requester( name => 'Test', email => 'Test@email.com' );

Returns a WebService::Freshservice::User object on success, croaks on
failure.

'name' is a mandatory attribute and requires at least one of 'email',
'phone' or 'mobile'.

Also accepts the following optional attributes: address, description,
external_id, job_title, language, timezone.

=cut  

method create_requester(
  :$name,
  :$email?, 
  :$address?,
  :$description?,
  :$job_title?,
  :$phone?,
  :$mobile?,
  :$language?,
  :$timezone?,
) {
  my $mandatory;
  $mandatory = $email if $email;
  $mandatory = $phone if $phone;
  $mandatory = $mobile if $mobile;
  croak("One of email, phone or mobile must be definded to create a user") unless $mandatory;
  croak("Name must be definded to create a user") unless $name;

  my $content;
  $content->{user}{name}         = $name;
  $content->{user}{email}        = $email if $email;
  $content->{user}{address}      = $address if $address;
  $content->{user}{description}  = $description if $description;
  $content->{user}{job_title}    = $job_title if $job_title;
  $content->{user}{phone}        = $phone if $phone;
  $content->{user}{mobile}       = $mobile if $mobile;
  $content->{user}{language}     = $language if $language;
  $content->{user}{timezone}     = $timezone if $timezone;
 
  my $data = $self->_api->post_api("itil/requesters.json",$content);
  return WebService::Freshservice::User->new( api => $self->_api, _raw => $data, id => $data->{user}{id} );
}

use WebService::Freshservice::Agent;

=method agent

  $freshservice->agent( id => '123456789' );

Returns a WebService::Freshservice::Agent on success, croaks on failure.
Optionally if you can use the attribute 'email' and it will search
returning the first result, croaking if not found.

=cut

method agent(...) {
  return $self->_user(@_);
}

=method agent

  $freshservice->agent( email => 'test@example.com');

Perform a search on the provided attribute and optional state. If
no query is set it will return the first 50 results.

Use one the following attributes, 'email', 'mobile' or 'phone'.

Optionally state can be set to one of 'verified', 'unverified',
'all' or 'deleted'. Defaults to 'all'.

Returns an array of 'WebService::Freshservice::Agent' objects or
empty array if no results are found.

=cut

method agents(...) {
  return $self->_search(@_);
}

1;
