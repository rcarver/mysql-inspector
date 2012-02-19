# mysql-inspector

mysql-inspector is a command line tool that helps you understand your
MySQL database schema. It works by writing a special type of dump file
to disk and then parsing it for various purposes.

## Usage

mysql-inspector supports several useful commands, but the first thing
you'll want to do is write at least one copy of your database to disk.

### write

The first thing to do is write a copy of your database to disk for
mysql-inspector to operate on. You can name this copy whatever you want,
by default it's called `current`.

    mysql-inspector write my_database

The result of this command will be a directory full of `.table` files,
one for each table in your database. A `.table` file is a simplified and
consistent representation of a table. Most importantly, it will not
change arbitrarly like a `mysqldump` file if the order of columns
changes or an `AUTO_INCREMENT` value is defined on the table.
mysql-inspector is purely concerned with the relational structure of the
table and favors this over an exact representation of the current
database schema. In practice, this means that you can commit this
directory to source control and easily view diffs over time without
excess line noise.

### grep

Search your entire database for columns, indices and constraints that
match a string or regex. For example, find everything that includes
'user_id' to see which tables relate to a user.

    mysql-inspector grep user_id
    mysql-inspector grep '^name'

Multiple matchers may be specified, which are AND'd together.

    mysql-inspector grep first name

### diff

Compare two schemas against each other. Perhaps your local development
and production databases have gone out of sync. First write a copy of
each and then let mysql-inspector show you the tables and attributes
that differ.

By default, a diff is performed on dumps named `current` and `target`.

    mysql-inspector write dev_database current
    mysql-inspector write prod_database target
    mysql-inspector diff

### load

Restore a version of your database schema. By default, the `current`
schema is used.

    mysql-inspector load my_database

## Rails and ActiveRecord Migrations

mysql-inspector can help you manage your database schema in a Rails
project. It replaces rake tasks such as `db:structure:dump` and writes
its own version at `db/current` instead of `db/structure.sql`. You'll
find this format much more convenient for checking into version control.

When a `schema_migrations` table is found, mysql-inspector writes its
contents to a file called `schema_migrations` within the dump directory.
When a dump is loaded via `mysql-inspector load` or `rake
db:structure:load`, the migrations will be restored.

## Author

Ryan Carver (@rcarver / ryan@ryancarver.com)

## License

Copyright © 2012 Ryan Carver. Licensed under Ruby/MIT, see LICENSE.
