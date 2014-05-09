# Philotic Examples
Read the code, yo!

## (Re)Initializing Named Queues
Any project that includes Philotic can include the `philotic:init_queues[path/to/named_queues.yml]` task.

For example:
```bash
PHILOTIC_RABBIT_HOST=localhost bundle exec rake philotic:init_queues[path/to/named_queues.yml]
```



