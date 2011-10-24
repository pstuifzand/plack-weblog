package Weblog;
use parent 'Plack::Component';
use strict;
use warnings;
use Data::Dumper;
use Weblog::DB;

use YAML::XS 'LoadFile';
use Plack::Util::Accessor qw/config/;
use Date::Period::Human;

sub call {
    my $self = shift;
    my $env = shift;

    my $title = $self->config->{weblog}{title};
    my $db = Weblog::DB->Connect(%{$self->config->{db}{weblog}});

    my $dph = Date::Period::Human->new();

    if ($env->{PATH_INFO} =~ m{^/code}) {
        return [ 302, [ 'Location', 'http://github.com/pstuifzand/plack-weblog' ], [] ];
    }
    elsif ($env->{PATH_INFO} =~ m{^/post/([a-z\-]+)$}) {
        my $slug = $1;
        my @sb;
        push @sb, "<DOCTYPE html><html><head><title>$title</title><link rel='stylesheet' href='/public/bootstrap.min.css' /><link rel='stylesheet' href='/public/style.css' /></head><body>\n";
        push @sb, "<div class='container'>";
        push @sb, "<h1><a href='/'>",$title,"</a></h1>\n";

        my $entry = $db->Entry($slug);
            push @sb, qq{<div class="entry">};
            push @sb, "<h2>",$entry->{title},"</h2>\n";
            push @sb, "<div class='content'>", $entry->{content}, "</div>", "\n";
            push @sb, "<div class='tools'>";
            push @sb, "  <span class='tool'><a href='/post/$entry->{slug}#comments'>Reageer</a></span> &middot; ";
            push @sb, "  <span class='created'><a href='/post/$entry->{slug}'>",$dph->human_readable($entry->{created}),"</a></span>";
            push @sb, "</div>\n";
            push @sb, qq{</div>};
        push @sb, qq{</div>};
        push @sb, "</body></html>\n";

        return [ 200, [ 'Content-Type', 'text/html' ], [ @sb ] ];
    }
    else {
        my @entries = $db->Entries;

        my @sb;
        push @sb, "<DOCTYPE html><html><head><title>$title</title><link rel='stylesheet' href='/public/bootstrap.min.css' /><link rel='stylesheet' href='/public/style.css' /></head><body>\n";
        push @sb, "<div class='container'>";
        push @sb, "<h1>",$title,"</h1>\n";

        push @sb, "<div class='row'>";
        push @sb, "<div class='span11'>";
        for my $entry (@entries) {
            push @sb, qq{<div class="entry">};
            push @sb, "<h2><a href='/post/$entry->{slug}'>",$entry->{title},"</a></h2>\n";
            push @sb, "<div class='content'>", $entry->{content}, "</div>", "\n";
            push @sb, "<div class='tools'>";
            push @sb, "  <span class='tool'><a href='/post/$entry->{slug}#comments'>Reageer</a></span> &middot; ";
            push @sb, "  <span class='created'><a href='/post/$entry->{slug}'>",$dph->human_readable($entry->{created}),"</a></span>";
            push @sb, "</div>\n";
            push @sb, qq{</div>};
        }
        push @sb, "</div>";
        push @sb, "<div class='span5'>";
        push @sb, q{<p>Stuur mij een e-mail: <a href="mailto:peter@tweevijftig.nl">peter@tweevijftig.nl</a></p>};
        push @sb, q{<p><a href="/code">Source code</a></p>};
        push @sb, qq{</div>};
        push @sb, qq{</div>};
        push @sb, "</body></html>\n";

        return [ 200, [ 'Content-Type', 'text/html' ], [ @sb ] ];
    }
}

1;

