# Netzke Core [![Gem Version](https://fury-badge.herokuapp.com/rb/netzke-core.png)](http://badge.fury.io/rb/netzke-core) [![Build Status](https://travis-ci.org/netzke/netzke-core.png?branch=master)](https://travis-ci.org/netzke/netzke-core) [![Code Climate](https://codeclimate.com/github/netzke/netzke-core.png)](https://codeclimate.com/github/netzke/netzke-core)

[RDocs](http://rdoc.info/projects/netzke/netzke-core)

Netzke Core is the bare bones of the [Netzke framework](http://netzke.org). For pre-built full-featured components (like grids, forms, tab/accordion panels, etc), see [netzke-basepack](http://github.com/netzke/netzke-basepack).

For rationale and mini-tutorial, refer to the meta gem's [README](https://github.com/netzke/netzke). Current README explains the Netzke architecture in some detail. Some knowledge of Sencha Ext JS (and Ruby, for that matter) may be required to fully understand this overview.

## What is a Netzke component

A Netzke component is a Ruby class (further referred to as "server class"), which is being represented by an Ext JS Component on the server-side (further referred to as "client class"). The responsibility of the server class is to "assemble" the client class and provide the configuration for its instance (further referred as "client class instance"). Even if it may sound a bit complicated, Netzke provides a simple API for defining and configuring the client class. See [Client class](#client-class) for details.

Further, each Netzke component inherits convenient API for enabling the communication between the client and server class. See [Client-server interaction](#client-server-interaction) for details.

With Netzke components being a Ruby class, and the client class being *incapsulated* in it, it is possible to use a Netzke component in your application by simply writing Ruby code. However, while creating a component, developers can fully use their Ext JS skills - Netzke puts no obstacles here.

A typical Netzke component's code is structured like this (on example of MyComponent):

```
your_web_app
  app
    components
      my_component.rb             <-- the Ruby class
      my_component
        some_module.rb            <-- optional extra Ruby code
        client
          some_dependency.js      <-- optional external JS library
          init_component.js       <-- optional override ("include") to the client class
          extra_functionality.js  <-- more override
          my_special_button.css    <-- optional custom CSS
```

## Client class

The generated client class is *inherited* (as defined by the Ext JS class system) from an Ext JS class, which by default is `Ext.panel.Panel`. For example, a component defined like this:

```ruby
class HelloWorld < Netzke::Base
end
```

will have the following client class generated by Netzke (simplified):

```javascript
Ext.define('Netzke.classes.HelloWorld', {"extend":"Ext.panel.Panel", "mixins":["Netzke.Core.Component"]});
```

`Netzke.Core.Component` contains a set of client class methods and properties common to every Netzke component.

Extending `HelloWorld` will be automatically reflected on the client-class level:

```ruby
class HelloNewWorld < HelloWorld
end
```

will have the following client class generated (simplified):

```javascript
Ext.define('Netzke.classes.HelloNewWorld', {"extend":"Netzke.classes.HelloWorld"});
```

Configuration of the client-class can be done by using the `Netzke::Base.client_class`. For example, in order to inherit from a different Ext JS component, and to mix in the methods defined in the `client` subfolder:

```ruby
class MyTabPanel < Netzke::Base
  client_class do |c|
    c.extend = "Ext.tab.Panel"
    c.include :extra_functionality
  end
end
```

The code above will set the `extend` property to "Ext.tab.Panel", and will mix in the following scripts:

  * `app/components/my_tab_panel/client/my_tab_panel.js` (if that exists)
  * `app/components/my_tab_panel/client/extra_functionality.js`

For more details on defining the client class, refer to [Netzke::Core::ClientClassConfig](http://rdoc.info/github/netzke/netzke-core/Netzke/Core/ClientClassConfig).

## Composition

Any Netzke component can define child components, which can either be statically nested in the compound layout (e.g. as different regions of the ['border' layout]("http://docs.sencha.com/ext-js/4-1/#!/api/Ext.layout.container.Border")), or dynamically loaded at a request (as in the case of the edit form window in `Netzke::Basepack::GridPanel`, for example).

### Defining child components

You can define a child component by calling the `component` class method which normally requires a block:

```ruby
component :users do |c|
  c.klass = GridPanel
  c.model = "User"
  c.title = "Users"
end
```

### Nesting components

Declared components can be referred to in the component layout:

```ruby
def configure(c)
  super
  c.items = [
    { xtype: :panel, title: "Simple Ext panel" },
    :users
  ]
end
```

### Dynamic loading of components

Next to being statically nested in the layout, a child component can also be dynamically loaded by using client class' `netzkeLoadComponent` method:

    this.netzkeLoadComponent('users');

this will load the "users" component and [add](http://docs.sencha.com/ext-js/4-1/#!/api/Ext.container.Container-method-add) it to the current container.

For more details on dynamic component loading refer to inline docs of [javascript/ext.js](https://github.com/netzke/netzke-core/blob/master/javascripts/ext.js).

For more details on composition refer to [Netzke::Core::Composition](http://rdoc.info/github/netzke/netzke-core/Netzke/Core/Composition).

## Actions, toolbars, and menus

Actions are [used by Ext JS]("http://docs.sencha.com/ext-js/4-1/#!/api/Ext.Action") to share functionality and state among multiple buttons and menu items. Define actions with the `action` class method:

```ruby
action :show_report do |c|
  c.text = "Show report"
  c.icon = :report
end
```

The icon for this button will be `images/icons/report.png` (see [Icons support](#icons-support)).

Refer to actions in toolbars:

```ruby
def configure(c)
  super
  c.bbar = [:show_report]
end
```

Actions can also be referred to is submenus:

```ruby
  c.tbar = [{text: 'Menu', menu: {items: [:show_report]}}]
```

For more details on composition refer to [Netzke::Core::Actions](http://rdoc.info/github/netzke/netzke-core/Netzke/Core/Actions).

## Client-server interaction

Communication between the client class and the corresponding server class is done by means of defining *endpoints*. By defining an endpoint on the server, the client class automatically gets access to an equally named method that calls the server.

### Calling an endpoint from client class

By defining an endpoint like this:

```ruby
class SimpleComponent < Netzke::Base
  endpoint :whats_up do |greeting|
  # ...
  end
end
```

...the client class will obtain a method called `whatsUp`, that can be called on the `this.server` object like this:

```javascript
this.server.whatsUp(greeting, callback, scope);
```

The last 2 params are optional:

* `callback` - function to be called after the server successfully processes the endpoint call; the function will receive, as its only argument, the result of the `endpoint` block execution
* `scope` - context in which the callback function will be called; defaults to the component's instance

As of version 1.0, the endpoint may receive an arbitrary number of arguments, for example:

```javascript
this.server.doSomething('value 1', true, callback, scope);
```

```ruby
class SimpleComponent < Netzke::Base
  endpoint :do_something do |arg_1, arg_2|
    # arg_1 == 'value 1'
    # arg_2 == true
  end
end
```

### Calling client class methods from endpoint

An endpoint can instruct the client instance of the component to execute a set of methods in response, passing those methods arbitrary parameters, by using the magical `this` variable. For example:

```ruby
class SimpleComponent < Netzke::Base
  endpoint :whats_up_server do
    client.set_title("Response from server")
    client.my_method
  end
end
```

Here the client class will first call its `setTitle` method (defined in `Ext.panel.Panel`) with parameter passed from the endpoint. Then a custom method `myMethod` will be called with no parameters.

For more details on client-server communication see [Netzke::Core::Services]("http://rdoc.info/github/netzke/netzke-core/Netzke/Core/Services").

## Icons support

Netzke can optionally make use of icons for making clickable elements like buttons and menu items more visual. The icons should be (by default) located in `app/assets/images/icons`.

An example of specifying an icon for an action:

```ruby
action :logout do |c|
  c.icon = :door
end
```

The logout action will be configured with `public/assets/icons/door.png` as icon.

For more details on using icons refer to [Netzke::Core::Actions]("http://rdoc.info/github/netzke/netzke-core/Netzke/Core/Actions").

## I18n

Netzke Core will automatically include Ext JS localization files based on current `I18n.locale`.

Also, Netzke Core uses some conventions for localizing actions. Refer to [Netzke::Core::Actions](http://rdoc.info/github/netzke/netzke-core/Netzke/Core/Actions).

## Routing

Any Netzke component can react on a specific hash-route in the URL, which can be achieved by specifying `netzkeRoutes`
hash on the client class, similarly to how Ext JS handles routes in its controllers:

    // e.g. in my_component/client/my_component.js
    {
      netzkeRoutes: {
        'users': 'handleUsers',
        'users/:id': 'handleUser'
      },

      handleUsers: function() {},

      handleUser: function(userId) {},
    }

If a component gets loaded dynamically and it figures out that one of its routes is currently active, it'll trigger the
corresponding handler after being rendered.

## Requirements

* Ruby >= 2.0.0
* Rails ~> 4.2.0
* Ext JS = 5.1.0

## Installation

    $ gem install netzke-core

For the latest ("edge") stuff, instruct the bundler to get the gem straight from github:

```ruby
gem 'netzke-core', github: "netzke/netzke-core"
```

By default, Netzke assumes that your Ext JS library is located in `public/extjs`. It can be a symbolic link, e.g.:

    $ ln -s PATH/TO/YOUR/EXTJS/FILES public/extjs

*(Make sure that the location of the license.txt distributed with Ext JS is exactly `public/extjs/license.txt`)*

## Running tests

The bundled `spec/rails_app` application used for automated testing can be easily run as a stand-alone Rails app. It's a good source of concise, focused examples. After starting the application, access any of the test components (located in `spec/rails_app/app/components`) by using the following url:

    http://localhost:3000/netzke/components/{name of the component's class}

For example [http://localhost:3000/netzke/components/Endpoints](http://localhost:3000/netzke/components/Endpoints)

To run a specific Mocha JS spec (located in `spec/mocha`) for a component, append `?spec={name of spec}`, for example:

    [http://localhost:3000/netzke/components/Endpoints?spec=endpoints](http://localhost:3000/components/Endpoints?spec=endpoints)

To run all the tests (from the gem's root):

    $ rake

This assumes that the Ext JS library is located/symlinked in `spec/rails_app/public/extjs`. If you want to use Sencha CDN instead, run:

    $ EXTJS_SRC=cdn rake

## Contributions and support

Help developing Netzke by submitting a pull request when you think others can benefit from it.

If you feel particularily generous, you can support the author by donating a couple bucks a week at [GitTip](https://www.gittip.com/mxgrn).

## Useful links

* [Project website](http://netzke.org)
* [Live demo](http://netzke-demo.herokuapp.com) (features [Netzke Basepack](https://github.com/netzke/netzke-basepack), with sample code)
* [Twitter](http://twitter.com/netzke) - latest news about the framework

---
Copyright (c) 2009-2015 [Good Bit Labs Limited](http://goodbitlabs.com/), released under the GPLv3 license
