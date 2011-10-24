package Weblog::DB;
use strict;
use warnings;
use parent 'DBIx::DWIW';

use DateTime;
use DateTime::Format::MySQL;

sub _FilterEntry {
    my $self = shift;
    my $entry = shift;

    $entry->{created} = DateTime::Format::MySQL->parse_datetime($entry->{created});
    $entry->{created}->set_time_zone('Europe/Amsterdam');

    if ($entry->{changed}) {
        $entry->{changed} = DateTime::Format::MySQL->parse_datetime($entry->{changed});
        $entry->{changed}->set_time_zone('Europe/Amsterdam');
    }
    return $entry;
}

sub Entry {
    my $self = shift;
    my $slug = shift;
    return $self->_FilterEntry($self->Hash("SELECT * FROM `entry` WHERE `slug` = ?", $slug));
}

sub Entries {
    my $self = shift;
    my $limit = shift || 10;

    if (!($limit =~ m/^(\d+)$/)) {
        die "limit should be a number";
    }
    $limit = $1;
    my @entries = $self->Hashes("SELECT * FROM `entry` ORDER BY `created` DESC LIMIT $limit");

    @entries = map { $self->_FilterEntry($_) } @entries;

    return @entries;
}

1;
