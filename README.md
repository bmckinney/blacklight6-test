## Dependencies
To get started with Blacklight, first [install Ruby](https://gorails.com/setup/#ruby) and [install Rails](https://gorails.com/setup/#rails), if you don't have it installed already. You'll need Ruby 2.1 or higher, and Rails 3.2 or higher.

If you are installing/developing on Linux, you will also need a JavaScript runtime installed, e.g. nodejs.

### Got Ruby?

You should have Ruby 2.1 or greater installed.

```console
$ ruby --version
  ruby 2.3.0p0 (2015-12-25 revision 53290) [x86_64-darwin14]
```

### Got Rails?

Blacklight works with Rails 4.2 and Rails 5.x, although we strongly encourage you to use Rails 5.

```console
$ rails --version
  Rails 5.0.0.1
```

## Download and run the EDS Blacklight app

- Clone or download this project
- Run the following terminal commands in the project's root directory:
```console
bundle install
rake db:migrate
export EDS_USER="username"
export EDS_PASS="secret"
export EDS_PROFILE="eds-api"
rails server -b 0.0.0.0 -p 3000 -e development
```
- Open a browser to http://0.0.0.0:3000/



