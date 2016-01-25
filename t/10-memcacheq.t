# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date$
# Id:            $Id$
# $HeadURL$
#
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;
use Test::Trap;
use t::sock qw(setup teardown);

our $PKG = 'Net::MemcacheQ';

my $version;

eval {
  $version = qx(memcacheq -h | head -1) or croak $ERRNO;
} or do {
  plan skip_all => 'memcacheq not found';
  exit;
};

if($version !~ /0[.]2/smix) {
  plan skip_all => 'memcacheq version untested';
}

plan tests => 14;

use_ok($PKG);
can_ok($PKG, qw(new queues delete_queue push shift));

{
  my $nmq = $PKG->new();
  isa_ok($nmq, $PKG);
}

{
  my $nmq = $PKG->new;
  is($nmq->_host, '127.0.0.1', 'default host');
}

{
  my $nmq = $PKG->new({host => 'foobar'});
  is($nmq->_host, 'foobar', 'configured host');
}

{
  my $nmq = $PKG->new;
  is($nmq->_port, '22201', 'default port');
}

{
  my $nmq = $PKG->new({port => 12345});
  is($nmq->_port, 12345, 'configured port');
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is_deeply($nmq->queues, []);

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});

  $nmq->push('myqueue', 'my message');
  is_deeply($nmq->queues, ['myqueue 1/0']); # was ['myqueue']

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is($nmq->push('myqueue', 'my message'), q[], 'push new queue');
  is($nmq->shift('myqueue'), q[my message], 'pop existing queue');

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  is($nmq->delete_queue('myqueue'), q[], 'delete non-existent queue');

  teardown();
}

{
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  $nmq->push('myqueue', 'my message');
  is($nmq->delete_queue('myqueue'), q[], 'delete existing queue');

  teardown();
}

{
  no warnings qw(once);
  local $Net::MemcacheQ::DEBUG = 1;
  my $nmq = Net::MemcacheQ->new({
				 port => setup,
				});
  trap {
    $nmq->push('myqueue', 'my message');
    $nmq->shift('myqueue');
  };
  like($trap->stderr, qr/Going.*Read.*Processed.*Read.*Finished/smx, 'push+shift with debug');

  teardown();
}
