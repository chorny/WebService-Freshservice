package WebService::Freshservice::Agent;

use v5.010;
use strict;
use warnings;
use Method::Signatures 20140224;
use Carp qw( croak );
use WebService::Freshservice::User::CustomField;
use Moo;
use MooX::HandlesVia;
use namespace::clean;

# ABSTRACT: Freshservice User

# VERSION: Generated by DZP::OurPkg:Version

=head1 SYNOPSIS

  use WebService::Freshservice::Agent;

  my $request = WebService::Freshservice::Agent->new( api => $api, id => '1234567890' );

Requires an 'WebService::Freshservice::API' object and agent id.

=head1 DESCRIPTION

Provides a Freshservice agent object. Agents are read-only, all update methods
will result in a croak.

=cut

extends 'WebService::Freshservice::User';

# Fixed fields
has 'active_since'        => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'available'           => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'created_at'          => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'occasional'          => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'signature'           => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'signature_html'      => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'points'              => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'scoreboard_level_id' => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'ticket_permission'   => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'updated_at'          => ( is => 'ro', lazy => 1, builder => '_build_agent' );
has 'user_id'             => ( is => 'ro', lazy => 1, builder => '_build_user_override' );
has 'user_created_at'     => ( is => 'ro', lazy => 1, builder => '_build_user_override' );
has 'user_updated_at'     => ( is => 'ro', lazy => 1, builder => '_build_user_override' );

# Updateable Fields

method _build__raw {
  return $self->api->get_api( "agents/".$self->id.".json" );
}

method _build_user {
  # Grab our calling method by dropping 'WebService::Freshservice::User::'
  my $caller = substr((caller 1)[3],32);
  return $self->_raw->{agent}{user}{$caller};
}

method _build_user_override {
  # Grab our calling method by dropping 'WebService::Freshservice::Agent::'
  my $caller = substr((caller 1)[3],38);
  return $self->_raw->{agent}{user}{$caller};
}

method _build_agent {
  # Grab our calling method by dropping 'WebService::Freshservice::Agent::'
  my $caller = substr((caller 1)[3],33);
  return $self->_raw->{agent}{$caller};
}

method _build_custom_field {
  my $custom_field = $self->_raw->{agent}{user}{custom_field};
  my $fields = { };
  foreach my $key ( keys %$custom_field ) {
    $fields->{$key} = WebService::Freshservice::User::CustomField->new(
      id      => $self->id,
      api     => $self->api,
      field   => $key,
      value   => $custom_field->{$key},
    );
  }
  return $fields;
}

method get_custom_field($field) {
  croak "Custom field must exist in freshservice" 
    unless exists $self->_raw->{agent}{user}{custom_field}{$field};
  return $self->_get_cf($field);
}

method delete_requester {
  croak("This method is not available to Agents");
}

method update_requester {
  croak("This method is not available to Agents");
}

method set_custom_field {
  croak("This method is not available to Agents");
}

1;
