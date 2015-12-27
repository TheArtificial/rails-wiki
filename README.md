# Rails Wiki

A small Rails engine that provides a git-based Markdown wiki.

## How it Works

Rails Wiki is based on [gollum-lib](https://github.com/gollum/gollum-lib). None of [Gollum](https://github.com/gollum/gollum/wiki)'s layout (e.g. sidebars, headers, footers) are implemented, and a many of the text filters (e.g. macros, code, diagrams) have been disabled. Also unlike Gollum, the hierarchy of pages is considered meaningful.

The storage structure will be familiar to users of Middleman or Jekyll. Each page is an `.md` file with YAML frontmatter for metadata. Other files are treated as attachments to the page associated with their containing directory.

All storage is via a local Git repository. Optionally, a remote can be specified and changes will be pushed to it.

_TODO: review and document remote behavior_

## Installation

Add Rails Wiki to your Gemfile

    gem 'rails-wiki'

Your application controller needs to provide two methods:

- `auth_required` is called on every request
- `current_user` returns a _user object_

The user object must response to `.name` and `.email` with string values.

## Configuration

In your `routes.rb`, specify a mount point:

    mount Wiki::Engine, at: '/wiki'

In your `config/environment/*` files, configure the wiki:

    require 'rails-wiki'
    Wiki.local_directory = 'db/wiki'

_TODO: move this configuration to an initializer?_

## Usage

Pathnames that begin with underscore (`_`) are reserved. Besides

## Feature Roadmap

1. Markdown link rooting
1. Recursive page deletion
1. Individual attachment deletion
1. Path redirection rules
1. Configurable help paths
1. Nicer attachment upload
1. Nicer page editing
