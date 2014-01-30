desc "initialize named durable queues"
namespace :eb do
  task :init_queues, :filename do |t, args|
    raise "You must specify a file name for #{t.name}: rake #{t.name}[FILENAME] #yes, you need the brackets, no space." if !args[:filename]

    # ENV['INITIALIZE_NAMED_QUEUE'] must equal 'true' to run Philotic.initialize_named_queue!
    ENV['INITIALIZE_NAMED_QUEUE'] = 'true'

    require 'philotic'

    @filename = args[:filename]
    queues = YAML.load_file(@filename)

    EM.run do
      def init_queues queues, index = 0
        Philotic.initialize_named_queue!("#{queues.keys[index]}", queues[queues.keys[index]]) do |q|
          if index == queues.size - 1
            Philotic::Connection.close { EM.stop }
          else
            init_queues queues, index + 1
          end
        end
      end

      init_queues queues
    end
  end
end
