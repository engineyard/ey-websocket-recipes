# Websockets on stable-v5 #

This bundle of custom cookbooks exists as a jumping off point for running a websocket server for use in a Rails application with the suggested best practices.

The primary focus of this setup revolves around serving websockets via Puma running on a dedicated server to reduce the strain on application servers.

Presently, the supported websocket configuration is [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html), but the changes necessary to use [AnyCable](https://github.com/anycable/anycable) or [Faye](https://faye.jcoglan.com/ruby.html) are fairly trivial.

*Note: While there's no reason that you couldn't customize the cookbooks further to allow for a multi-application setup, these cookbooks are meant to act on an environment that provides only a single Application.*

## Caveats ##

There are a few items of note that one should consider before using these cookbooks:

* As is the case with all custom cookbooks that we provide, these cookbooks are not officially supported. That said, if you try them out and have problems, we would very much appreciate it if you would create an issue on the repo, submit a support ticket, or both.
* At present, the only websocket system that is supported is Rails' own `ActionCable`.
* This requires the addition of an `upstream` in the nginx config. This is done in `/etc/nginx/http-custom.conf`, so if you are already adding a custom configuration to that file, you'll want to merge it with the template in `cookbooks/custom-websocket/templates/default/upstreams.conf.erb`.
* Much like above, the `custom-env_vars` cookbook is also used to set up some environment variables to help your application communicate with the websocket server. If you already use this cookbook, you will most likely want to merge this as well.
* This requires a few changes to your application (detailed below in the "Installation" section, step 7).

## Installation ##

1. Boot an environment using the stable-v5 stack.
2. Download the Engine Yard Core API client gem on your local machine.
3. Clone this repository on your local machine.
4. Customize the websocket configuration
5. Upload the custom chef recipes from your local machine.
6. Click Apply on the environment page on Engine Yard Cloud
7. Update and deploy your application

### 1. Boot a stable-v5 environment ###

These cookbooks configure your websocket server to run on a specific utility instance. If your use case dictates that you need the websocket server running elsewhere, you will need to further customize it.

To use the default configuration, boot a utility instance named "websocket" on your environment. You can do this on a new environment or add the utility instance on an existing stable-v5 environment.

### 2. Download the engineyard gem ###

On your local machine, run `gem install ey-core`.

### 3. Clone the custom websocket chef recipes ###

On your local machine, run 

```
git clone https://github.com/engineyard/ey-websocket-recipes
```

If you have other custom coobooks for your environment, you'll need to do a bit of work to incorporate the websocket cookbooks into your custom cookbooks. Othwerwise, you can just upload from the ey-websocket-recipes directory.

### 4. Customize the websocket configuration ###

There are a few values that need to be changed across the cookbooks in this repo to actually use them with your app:

#### custom-websocket ####

In `cookbooks/custom-websocket/attributes/default.rb`, you'll want to change at least the following values to match your application: `websocket['app']` and `websocket['mountpoint']`.

The first of these is the name of your application (as it appears in the /data directory on your app instances).

The second is the URL path to which the websocket server should be mounted. Most typically, this is "/cable" for ActionCable-powered apps, but you can change this to just about anything that you'd like, so long as you configure your application to use the proper URL for cable connections.

#### custom-env_vars ####

While not *strictly* necessary, we've found that it works pretty well to configure the production cable URL and allowed hosts via environment variables. to that end, particularly if you're following this guide all the way through, you'll want to update `cookbooks/custom-env_vars/files/default/env.custom` with good values for `WS_URL` and `ALLOWED_REQUEST_ORIGIN`.

The first of these is the fully-qualified `ws` URL that clients should use to interact with your websocket server (ie 'ws://myapp.com/cable').

The second of these is basically just your app's primary URL (ie 'http://myapp.com').

### 5. Upload the custom chef recipes ###

On your local machine, `cd` to the directory that contains your `cookbooks` directory and run the following:

```
ey-core recipes upload -c account_name -e environment_name
```

### 6. Click Apply on the environment page on Engine Yard Cloud ###

Go to the environment page on Engine Yard Cloud. Click the Apply button. This will run the main chef recipes and custom chef recipes on a *single* chef run.

### 7. Update and deploy your application ###

The process so far has put the groundwork in place to be able to run a standalone websocket (ActionCable) server, but there are a few changes that are necessary to your application in order to make this setup work as intended. This mostly comes down to configuring your routes, configuring ActionCable within the app, and adding some deploy hooks to ensure that some configs are in place and that the websocket server gets restarted on each deploy.

After you make these changes to your application, you should push to your upstream git repo, deploy, and test the websocket-enabled portions of your app.

#### Routes ####

In development, it's usually advised that you mount ActionCable directly in your app's `config/routes.rb` via `mount ActionCable.server => '/cable'`. Unfortunately, that may conflict with the configuration that allows for an external websocket server to be used. That being the case, if you want to still have a handy `/cable` mountpoint in development, you might do that like so:

```ruby
Rails.application.routes.draw do
  if Rails.env.development?
    mount ActionCable.server => '/cable'
  end

  resources :posts, only: [:show]

  root to: 'posts#index'
end
```

#### ActionCable Configuration ####

In order for the app to know where it should tell clients to connect for websocket interactions, you need to configure this in your application's environment-specific configuration. This setup is intended primarily for production use cases, so it's advised that you configure this in `config/environments/production.rb`, but you might also want to do this for `config/environments/staging.rb` if you are using a "staging" environment.

The values that you'll want to configure are the `url` and `allowed_request_origins` for ActionCable. If you're not using env vars as suggested above, that might look like this:

```ruby
config.action_cable.url = 'ws://myapp.com/cable'
config.action_cable.allowed_request_origins = ['http://myapp.com/cable']
```

If you're using the `custom-env_vars` cookbook as suggested above (or if you're using the Environment Variables UI in the Cloud dashboard), you would do this instead:

```ruby
config.action_cable.url = ENV['WS_URL']
config.action_cable.allowed_request_origins = [ ENV['ALLOWED_REQUEST_ORIGIN'] ]
```

#### Deploy Hooks ####

If you look in the `deploy` directory in this repo, we've provided some boilerplate Ruby deploy hooks. Here's a rough breakdown of those:

* `before_migrate.rb` - This stops the currently-running websocket server on the websocket utility instance. While this is incredibly nice-to-have, it's not required.
* `before_symlink.rb` - This links the `cable.yml` generated by the `custom-websocket` cookbook into the application's config. This is ***absolutely*** required for the websocket connections to work properly.
* `after_restart.rb` - This starts the websocket server on the websocket utility instance. This is nice-to-have, but is only required if you're stopping the websocket server in an earlier hook (like `before_migrate.rb`).

If you copy this `deploy` directory into your app's repo, push, and deploy, it will do the things that are necessary. The caveat here is that if you have changed the utility name in `cookbooks/custom-websocket/attributes/default.rb`, you will want to modify `before_migrate.rb` and `after_restart.rb` to use the correct instance name.
