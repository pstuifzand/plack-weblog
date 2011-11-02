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

    $entry->{comment_count} = $self->Scalar("SELECT COUNT(*) FROM `comment` WHERE `entry_id` = ?", $entry->{id});
    return $entry;
}

sub Entry {
    my $self = shift;
    my $site_id = shift;
    my $slug = shift;

    my $obj = $self->Hash("SELECT * FROM `entry` WHERE `site_id` = ? AND `slug` = ?", $site_id, $slug);
    my $entry = $self->_FilterEntry($obj);
    $entry->{comments} = [ $self->Hashes("SELECT * FROM `comment` WHERE `entry_id` = ?", $entry->{id}) ];
    return $entry;
}

sub Entries {
    my $self = shift;
    my $site_id = shift;
    my $limit = shift || 10;

    if (!($limit =~ m/^(\d+)$/)) {
        die "limit should be a number";
    }
    $limit = $1;
    my @entries = $self->Hashes("SELECT * FROM `entry` WHERE `site_id` = ? ORDER BY `created` DESC LIMIT $limit",
        $site_id);

    @entries = map { $self->_FilterEntry($_) } @entries;

    return @entries;
}

sub AddComment {
    my ($self, $site_id, $slug, $comment) = @_;

    my $entry_id = $self->Scalar("SELECT `id` FROM `entry` WHERE `site_id` = ? AND `slug` = ? LIMIT 1", $site_id, $slug);

    $self->Execute("INSERT INTO `comment` (`entry_id`, `name`, `email`, `comment`, `user_agent`, `ip`)
        VALUES(?, ?, ?, ?, ?, INET_ATON(?))", 
        $entry_id, $comment->{name}, $comment->{email}, $comment->{comment},
        $comment->{user_agent}, $comment->{remote_ip});

    die $@ if $@;
    return;
}

sub _create_slug {
    my ($title) = @_;
    $title = lc $title;
    $title =~ s/[^a-z0-9]+/-/g;
    $title =~ s/-+/-/g;
    $title =~ s/^-//g;
    $title =~ s/-$//g;
    return $title;
}

sub CreateEntry {
    my ($self, $site_id, $entry) = @_;

    $entry->{slug} = _create_slug($entry->{title});

    $self->Execute("INSERT INTO `entry` (`site_id`, `slug`, `title`, `content`, `created`)
        VALUES (?, ?, ?, ?, NOW())", $site_id, $entry->{slug}, $entry->{title}, $entry->{content});

    return;
}

1;

