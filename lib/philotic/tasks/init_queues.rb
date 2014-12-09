desc "initialize named durable queues"
namespace :philotic do
  task :init_queues, :filename do |t, args|
    raise "You must specify a file name for #{t.name}: rake #{t.name}[FILENAME] #yes, you need the brackets, no space." if !args[:filename]

    # ENV['PHILOTIC_INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!
    ENV['PHILOTIC_INITIALIZE_NAMED_QUEUE'] = 'true'

    require 'philotic'

    @filename = args[:filename]
    queues    = YAML.load_file(@filename)
    Philotic.connect!
    queues.each_pair do |queue_name, queue_options|
      Philotic.initialize_named_queue!(queue_name, queue_options)
    end
  end
end
