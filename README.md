# Rails Wiki

A small Rails engine that provides an opinionated, git-based, Markdown wiki.

**This has been abstracted from a proprietary tool, and so is not well documented and lacks a standalone test suite.**

This aims to become a suitable replacement for [GollumRails](https://github.com/dancinglightning/gollum_rails), which does not actually use gollum-lib, but also provides an engine with Gollum-like features. (The name is historic.)

If instead of a mountable engine you want to use gollum-lib to weave wiki functionality into your own models and views, consider [gollum_rails](https://github.com/nirnanaaa/gollum_rails). If you just want a wiki that uses your existing database, look at [Irwi](https://github.com/alno/irwi)

Rails Wiki exists because we desired a git-backed wiki using Markdown, YAML frontmatter, and a hierarchical namespace for pages and attachments.

## How it Works

Rails Wiki is based on [gollum-lib](https://github.com/gollum/gollum-lib). None of [Gollum](https://github.com/gollum/gollum/wiki)'s layout (e.g. sidebars, headers, footers) are implemented, and most of the text filters (e.g. macros, code, diagrams) have been disabled. Also unlike Gollum, the hierarchy of pages is considered meaningful.

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

You will probably wish to override the sparse view layout. Create a `layouts/wiki` (e.g. at `app/views/layouts/wiki.html.erb`) within your app, using the content blocks seen in the [default layout](app/views/layouts/wiki.html.erb).

### Deployment Warning

Until [gollum-lib#180](https://github.com/gollum/gollum-lib/issues/180) is resolved there is a hardcoded but unnecessary dependency on grit in gollum-lib. This in turn requires charlock_holmes, which can be [problematic](http://tooky.co.uk/using-charklock_holmes-on-heroku/).

To avoid this, you may use our temporary fork of gollum-lib by including it in your Gemfile prior to rails-wiki:

    gem 'gollum-lib', git: 'https://github.com/TheArtificial/gollum-lib.git', branch: 'master'

([This discussion](http://stackoverflow.com/questions/6499410/ruby-gemspec-dependency-is-possible-have-a-git-branch-dependency) may be interesting if you're curious about this approach to a temporary issue.)

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
2. Recursive page deletion
3. Individual attachment deletion
4. ~~Path redirection rules~~
5. Configurable help paths
6. Nicer attachment upload
7. Nicer page editing
