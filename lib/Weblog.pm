package Weblog;
use parent 'Plack::Component';
use strict;
use warnings;
use Data::Dumper;
use DBIx::DWIW;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};

    my $db = DBIx::DWIW->Connect(%{$self->config->{db}{weblog}});

    my @entries = $db->Hashes("SELECT * FROM `entry` ORDER BY `created` DESC LIMIT 10");

    my @sb;
    push @sb, "<DOCTYPE html><html><head><title>$title</title><link rel='stylesheet' href='/public/bootstrap.min.css' /><link rel='stylesheet' href='/public/style.css' /></head><body>\n";
    push @sb, "<div class='container'>";
    push @sb, "<h1>",$title,"</h1>\n";

    push @sb, "<div class='row'>";
    push @sb, "<div class='span11'>";
    for my $entry (@entries) {
        push @sb, qq{<div class="entry">};
        push @sb, "<h2>",$entry->{title},"</h2>\n";
        push @sb, "<div class='content'>", $entry->{content}, "</div>", "\n";
        push @sb, "<div class='created'>", $entry->{created}, "</div>", "\n";
        push @sb, qq{</div>};
    }
    push @sb, "</div>";
    push @sb, "<div class='span5'>";
    push @sb, q{<p>Stuur mij een e-mail: <a href="mailto:peter@tweevijftig.nl">peter@tweevijftig.nl</a></p>};
    push @sb, qq{</div>};
    push @sb, qq{</div>};
    push @sb, "</body></html>\n";

    return [ 200, [ 'Content-Type', 'text/html' ], [ @sb ] ];
}

1;

