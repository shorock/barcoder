class BarcoderRunner < JobRunner


  def self.instance_for(job)
    if job.job_type == "barcoder_job"
      self.new(job)
    else
      nil
    end
  end

  def barcode( ao, barcode = nil )
    barcode ||= "aspace.#{ao.id}" 
            $stderr.puts "2" * 100 
            $stderr.puts barcode 
            $stderr.puts ao.inspect 
            $stderr.puts "2" * 100 
     
    ao.instance.each do |instance|
      instance.container.each do |container|
        type = container.type_1 || "notype" 
        indicator = container.indicator_1 || "noindicator" 
        container.barcode_1 = "#{barcode}.#{type}.#{indicator}"
        $stderr.puts container.save
        $stderr.puts "3" * 100 
      end 
    end
    
    ao.children.each do |child|
      barcode(child, barcode)
    end
  
  end

  def run
    super

    job_data = @json.job
    parsed = JSONModel.parse_reference(job_data['ref'])
    target = Resource.any_repo[parsed[:id]]


    begin
      DB.open( DB.supports_mvcc?, 
             :retry_on_optimistic_locking_fail => true ) do
        begin
          RequestContext.open( :current_username => @job.owner.username,
                              :repo_id => @job.repo_id) do  
            @job.write_output( "Starting resource #{target.id}" ) 
             
            $stderr.puts "1" * 100 
            $stderr.puts target.children.inspect 
            $stderr.puts "1" * 100 
            target.children.each do |ao|
              barcode(ao) 
            end
            @job.write_output( "Finishing #{target.id}" ) 
          end 
        rescue Exception => e
          terminal_error = e
          raise Sequel::Rollback
        end
      end
    
    rescue
      terminal_error = $!
    end
 
    if terminal_error
      @job.write_output(terminal_error.message)
      @job.write_output(terminal_error.backtrace)
      
      raise terminal_error
    end
  
  end



end
