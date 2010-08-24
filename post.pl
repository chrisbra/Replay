#!/usr/bin/perl
use strict;
use warnings;

use WWW::Mechanize;

#my $sid=shift @ARGV;
my $sid=3216;
my $file=shift @ARGV;
my $scriptversion=shift @ARGV;
my $versioncomment=shift @ARGV;

my @userpasswordpair=qw(user password);

my $mech=WWW::Mechanize->new(autocheck => 1);
$mech->get("http://www.vim.org/login.php");
$mech->submit_form(
    form_name => "login",
    with_fields => {
        userName => $userpasswordpair[0],
        password => $userpasswordpair[1],
    },
);
$mech->get("http://www.vim.org/scripts/script.php?script_id=$sid");
$mech->follow_link(text => 'upload new version');
$mech->form_name("script");
$mech->field(script_file => $file);
$mech->field(vim_version => 7.2);
$mech->field(script_version => $scriptversion);
$mech->field(version_comment => $versioncomment);
$mech->click_button(value => "upload");
print $mech->content;
