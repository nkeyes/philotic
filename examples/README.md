# Philotic Examples
Read the code, yo!

## (Re)Initializing Named Queues
Any project that includes Philotic can include the `eb:init_queues[path/to/named_queues.yml]` task.

For example:
```bash
EVENTBUS_RABBIT_HOST=ec2-something.compute-1.amazonaws.com bundle exec rake eb:init_queues[path/to/named_queues.yml]
```



