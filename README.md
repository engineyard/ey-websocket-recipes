# Websockets on stable-v5 #

This bundle of custom cookbooks exists as a jumping off point for running a websocket server for use in a Rails application with the suggested best practices.

The primary focus of this setup revolves around serving websockets via Puma running on a dedicated server to reduce the strain on application servers.

Presently, the supported websocket configuration is [ActionCable](https://guides.rubyonrails.org/action_cable_overview.html), but the changes necessary to use [AnyCable](https://github.com/anycable/anycable) or [Faye](https://faye.jcoglan.com/ruby.html) are fairly trivial.

*Note: While there's no reason that you couldn't customize the cookbooks further to allow for a multi-application setup, these cookbooks are meant to act on an environment that provides only a single Application.*

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

TODO: write this

### 5. Upload the custom chef recipes ###

On your local machine, `cd` to the directory that contains your `cookbooks` directory and run the following:

```
ey-core recipes upload -c account_name -e environment_name
```

### 6. Click Apply on the environment page on Engine Yard Cloud ###

Go to the environment page on Engine Yard Cloud. Click the Apply button. This will run the main chef recipes and custom chef recipes on a *single* chef run.

### 7. Update and deploy your application ###

TODO: write this

