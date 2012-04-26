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

    if ($entry->{date}) {
        $entry->{date} = DateTime::Format::MySQL->parse_datetime($entry->{date} . ' ' . $entry->{time});
        $entry->{date}->set_time_zone('Europe/Amsterdam');
        $entry->{date}->set_locale('nl_NL');
    }

    $entry->{comment_count} = $self->Scalar("SELECT COUNT(*) FROM `comment` WHERE `entry_id` = ?", $entry->{id});
    return $entry;
}

sub Event {
    my ($self, $site_id, $year, $month, $day, $slug) = @_;

    my $event = $self->Hash(<<"SQL", $site_id, sprintf('%04d-%02d-%02d', $year,$month,$day), $slug);
SELECT *
FROM `event` AS `ev`
LEFT JOIN `entry` AS `e`
ON `ev`.`entry_id` = `e`.`id`
WHERE `e`.`site_id` = ?
AND `ev`.`date` = ?
AND `e`.`slug` = ?
SQL
    die $@ if $@;

    #my $entry = $self->_FilterEntry($event);
    return $event;
}

sub Events {
    my ($self, $site_id) = @_;

    my @events = $self->Hashes(<<"SQL", $site_id);
SELECT *
FROM `event` AS `ev`
LEFT JOIN `entry` AS `e`
ON `ev`.`entry_id` = `e`.`id`
WHERE `e`.`site_id` = ?
AND `ev`.`date` >= CURDATE()
ORDER BY `ev`.`date`, `ev`.`time`
SQL
    die $@ if $@;

    @events = map {$self->_FilterEntry($_)} @events;
    @events;
}

sub Entry {
    my $self = shift;
    my $site_id = shift;
    my $slug = shift;

    my $obj = $self->Hash("SELECT * FROM `entry` WHERE `site_id` = ? AND `slug` = ?", $site_id, $slug);

    my $entry = $self->_FilterEntry($obj);
    $entry->{comments} = [ $self->Hashes("SELECT * FROM `comment` WHERE `entry_id` = ?", $entry->{id}) ];

    if ($entry->{type} eq 'event') {
        my $event_data = $self->Hash("SELECT `date`, `time` FROM `event` WHERE `entry_id` = ?", $entry->{id});
        die $@ if $@;
        $entry = { %$entry, %$event_data };
        $entry->{time} =~ s/:00$//;
    }

    return $entry;
}

sub Pages {
    my $self = shift;
    my $site_id = shift;

    my @entries = $self->Hashes("SELECT * FROM `entry` WHERE `site_id` = ? AND `type` = 'page' ORDER BY `title` ASC",
        $site_id);

    @entries = map { $self->_FilterEntry($_) } @entries;

    return @entries;
}

sub Entries {
    my $self = shift;
    my $site_id = shift;
    my $limit = shift || 10;

    if (!($limit =~ m/^(\d+)$/)) {
        die "limit should be a number";
    }
    $limit = $1;
    my @entries = $self->Hashes("SELECT * FROM `entry` WHERE `site_id` = ? AND `type` = 'blogpost' ORDER BY `created` DESC LIMIT $limit",
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

    if (!$entry->{slug}) {
        $entry->{slug} = _create_slug($entry->{title});
    }

    $self->Execute("INSERT INTO `entry` (`site_id`, `type`, `slug`, `title`, `content`, `created`)
        VALUES (?, ?, ?, ?, ?, NOW())", $site_id, $entry->{type}, $entry->{slug}, $entry->{title}, $entry->{content});
    my $id = $self->InsertID();

    if ($entry->{type} eq 'event') {
        $self->Execute("REPLACE INTO `event` (`event_id`, `date`, `time`) VALUES (?, ?, ?)",
            $id, $entry->{date}, $entry->{time});
    }

    return;
}

sub UpdateEntry {
    my ($self, $site_id, $entry) = @_;

    $self->Execute("UPDATE `entry` SET `type` = ?, `slug` = ?, `title` = ?, `content` = ?, `changed` = NOW() WHERE `site_id` = ? AND `id` = ?",
        $entry->{type}, $entry->{slug}, $entry->{title}, $entry->{content}, $site_id, $entry->{id});
    die $@ if $@;
    my $id = $entry->{id};

    if ($entry->{type} eq 'event') {
        $self->Execute("REPLACE INTO `event` (`event_id`, `date`, `time`) VALUES (?, ?, ?)",
            $id, $entry->{date}, $entry->{time});
    }
    return;
}

sub GetSiteInfo {
    my ($self, $site_id) = @_;
    return $self->Hash("SELECT * FROM `site_text` WHERE `site_id` = ?", $site_id);
}

sub SetSiteInfo {
    my ($self, $site_id, $info) = @_;

    $self->Execute("INSERT INTO `site_text` (`site_id`, `title`) VALUES (?,?) ON DUPLICATE KEY UPDATE `title` = VALUES(`title`)", $site_id, $info->{title});
    return;
}

1;

