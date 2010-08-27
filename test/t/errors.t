# vi:filetype=perl

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(2);

plan tests => repeat_each() * blocks() + 2;

$ENV{TEST_NGINX_MYSQL_PORT} ||= 3306;

our $http_config = <<'_EOC_';
    upstream foo {
        drizzle_server 127.0.0.1:$TEST_NGINX_MYSQL_PORT protocol=mysql
                       dbname=ngx_test user=ngx_test password=ngx_test;
    }
_EOC_

worker_connections(128);
run_tests();

no_diff();

__DATA__

=== TEST 1: bad query
little-endian systems only

--- http_config eval: $::http_config
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "update table_that_doesnt_exist set name='bob'";
    }
--- request
GET /mysql
--- error_code: 410
--- response_body_like: 410 Gone
--- timeout: 3



=== TEST 2: wrong credentials
little-endian systems only

--- http_config
    upstream foo {
        drizzle_server 127.0.0.1:3306 dbname=test
             password=wrong_pass user=monty protocol=mysql;
        drizzle_keepalive mode=single max=2 overflow=reject;
    }
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "update cats set name='bob' where name='bob'";
    }
--- request
GET /mysql
--- error_code: 502



=== TEST 3: no database
little-endian systems only

--- http_config
    upstream foo {
        drizzle_server 127.0.0.1:1 dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive mode=single max=2 overflow=reject;
    }
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "update cats set name='bob' where name='bob'";
    }
--- request
GET /mysql
--- error_code: 502
--- skip_nginx: 1: < 0.8.17



=== TEST 4: multiple queries
little-endian systems only

--- http_config eval: $::http_config
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "select * from cats; select * from cats";
    }
--- request
GET /mysql
--- error_code: 500



=== TEST 5: missing query
little-endian systems only

--- http_config eval: $::http_config
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
    }
--- request
GET /mysql
--- error_code: 500



=== TEST 6: empty query
little-endian systems only

--- http_config eval: $::http_config
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        set $query "";
        drizzle_query $query;
    }
--- request
GET /mysql
--- error_code: 500



=== TEST 7: empty pass
little-endian systems only

--- http_config eval: $::http_config
--- config
    location /mysql {
        set $backend "";
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "update cats set name='bob' where name='bob'";
    }
--- request
GET /mysql
--- error_code: 500



=== TEST 8: no database (for versions older than nginx-0.8.17)
little-endian systems only

--- http_config
    upstream foo {
        drizzle_server 127.0.0.1:1 dbname=test
             password=some_pass user=monty protocol=mysql;
        drizzle_keepalive mode=single max=2 overflow=reject;
    }
--- config
    location /mysql {
        set $backend foo;
        drizzle_pass $backend;
        drizzle_module_header off;
        drizzle_query "update cats set name='bob' where name='bob'";
    }
--- request
GET /mysql
--- error_code: 500
--- SKIP

