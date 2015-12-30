# Rails Wiki

A small Rails engine that provides an opinionated, git-based, Markdown wiki.

WARNING: this has been abstracted from a proprietary tool, and so is poorly documented and lacks a standalone test suite.

This may be a suitable replacement for [GollumRails](https://github.com/dancinglightning/gollum_rails), which confusingly does not use gollum-lib, but also provides an engine with Gollum-like features.

If instead of a turnkey engine you want to use gollum-lib and all of its power from within your Rails app, consider [gollum_rails](https://github.com/nirnanaaa/gollum_rails).

Rails Wiki exists because we desired a git-backed wiki using Markdown, YAML frontmatter, and a hierarchical namespace for pages and attachments.

## How it Works

Rails Wiki is based on [gollum-lib](https://github.com/gollum/gollum-lib). None of [Gollum](https://github.com/gollum/gollum/wiki)'s layout (e.g. sidebars, headers, footers) are implemented, and a many of the text filters (e.g. macros, code, diagrams) have been disabled. Also unlike Gollum, the hierarchy of pages is considered meaningful.

The storage structure will be familiar to users of Middleman or Jekyll. Each page is an `.md` file with YAML frontmatter for metadata. Other files are treated as attachments to the page associated with their containing directory.

All storage is via a local Git repository. Optionally, a remote can be specified and changes will be pushed to it.

Optionally, a rather blunt attempt is made to pull/push changes to an upstream repository.

## Installation

Add `rails-wiki` to your Gemfile

    gem 'rails-wiki'

Your application controller needs to provide two methods:

- `auth_required` is called on every request
- `current_user` returns a _user object_

The user object must response to `.name` and `.email` with string values.

### Deployment Warning

Until [gollum-lib#180](https://github.com/gollum/gollum-lib/issues/180) is resolved there is a hardcoded but unnecessary dependency on grit. This requires the installation of charlock_holmes, which can be problematic.

See http://tooky.co.uk/using-charklock_holmes-on-heroku/ for tips on Heroku. We presently use this `.buildpack`:

    https://github.com/ddollar/heroku-buildpack-apt
    https://github.com/timolehto/heroku-bundle-config
    https://github.com/rcaught/heroku-buildpack-cmake
    https://github.com/heroku/heroku-buildpack-ruby

and an `Aptfile` specifying only `libicu-dev`.

If you would like to use rails-wiki and have difficulty due to this, open an issue and we'll fork gollum-lib to eliminate this dependency.

## Configuration and Integration

In your `routes.rb`, specify a mount point:

    mount Wiki::Engine, at: '/wiki'

In your `config/environment/*` files, configure the wiki:

    require 'rails-wiki'
    Wiki.local_directory = 'db/wiki'

While not recommended, upstream sync can be provided by setting additional properties on the module:

    Wiki.remote_url = "https://github.com/TheArtificial/wiki"
    Wiki.history_url = "https://github.com/TheArtificial/wiki/commits/master/"

_TODO: move this configuration to an initializer?_

See the test/dummy app for an example.

## Usage

Pathnames that begin with underscore (`_`) are reserved.

## Feature Roadmap

1. Markdown link rooting
1. Recursive page deletion
1. Individual attachment deletion
1. Path redirection rules
1. Configurable help paths
1. Nicer attachment upload
1. Nicer page editing
