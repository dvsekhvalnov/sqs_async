# SQS Async

## Changelog:
Fixed error handling defect to correctly recognize SQS REST API errors.

## A (mostly) non-blocking Amazon SQS client

The goal of this library is simple. For those of us needing a way to communicate with SQS 
using an evented solution, like EventMachine, there exists no library that will make the requests
without blocking the main thread and diminishing the value that EM provides.

This simple library is a work in progress that allows for this behavior. At the moment very few
options are supported but we will be add more as need arises and/or happily accept pull requests
from those of you out there who may have found this gem out of a similar need.

# Usage

In order to use the library, simply mix the SQS module into the class that will be making your calls to SQS. At somepoint, 
You'll want to ensure that you've set your keys and secret in that class. Will we go more global with configuration? Probably, 
but like my uncle Larry says: "If it don't hurt, don't change it."

    class MySQSClient
      include SQS
    
      def initialize
        @aws_key    = "YOUR KEY"
        @aws_secret = "SHHHHHHHHHHHHHHHHHHHHHH"
      end
    
    end

From there, you can make your sqs calls as part of your initialized object. Just be sure to do it inside of an
EventMachine run loop. 

    client = MySQSClient.new
    client.list_queues

# Conventions

The Library uses a simple "callback" aka "hollaback" system to communicate completion events. The last argument of all service calls 
is a hash of callbacks. Currently supported are :success and :failure. You can add others, we simply will ignore them. 

    client.list_queues( :success => lambda {|queues| puts queues } )

# Known Issues

At the moment, there is very little validation. So, it's important to validate your
data prior to placing submitting it to Amazon. Some bits that are important to the
success of sending a message (for example) are validated (signatures, keys, etc) but
items like Policies on set_queue_attributes are assumed "good" by the time you pass it in.

This is something that will be added in a future release... Stay Tuned or get your patch on. :)

# Changes

## 0.0.2
Implicit evaluation of expected actions
Base implementations of all SQS API methods.

## 0.0.1
Initial release. Only 3 endpoints supported.

# Long Term Goals
* Global Error Handling
* Include Message/AWS specific meta-data to response objects.
* Async support for other services in the AWS stack.
* Allow for drop-in alternatives to EventMachine

# Not interested in implementing...
* Backwards compatibility with past AWS APIs.

# Fork it.

We love to write and maintain code but there are only so many hours in a day! :) We encourage others to pick up where we left off and issue pull
requests back to us. We only ask a few things....

+ fork the project
+ create a feature branch
+ create your patch (be sure to include specs!)
+ make sure that you patch can be applied cleanly
+ send us a pull request
+ bask in the glory that is Open Source!

## Bonus points!

You get extra points for the following... 

+ Not blocking. Or minimize it as much as possible.
+ Not reaching out to the interwebs with your specs
+ Any new surface area additions to the API accept the hash with the supported callbacks.
+ Default callbacks are on keys :success and :failure

That's pretty much it. For all bugs/errata/whathaveyou we're using github for issues or contact us @ contact@edgecase.com

Thanks! 

-- Leon and John from EdgeCase
