class BarcoderRunner < JobRunner


  def self.instance_for(job)
    if job.job_type == "barcoder_job"
      self.new(job)
    else
      nil
    end
  end

  def get_barcode( container, barcode = nil )
    type = container.type_1 || "notype" 
    indicator = container.indicator_1 || "noindicator" 
    "#{barcode}.#{type}.#{indicator}"
  end
  
  def process_children(record, barcode)
    updated_records = [] 
    record.children.each do |child|
      updated_records += process_record(child, barcode)
      updated_records += process_children(child, barcode)
    end
    updated_records 
  end
 
  def process_record(record, barcode)
    updated_records = [] 
    @job.write_output( "processing record #{record.id}" ) 
    record.instance.each do |instance|
      instance.container.each do |container|
        next if container.barcode_1
        container.barcode_1 = get_barcode(container,barcode) 
        @job.write_output( "adding container barcode #{container.barcode_1} to record #{record.id}" ) 
        container.save              
        updated_records << "/repositories/#{@job.repo_id}/archival_objects/#{record.id}" 
      end 
    end
    updated_records 
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
            
            updated_records = []
            # we take the resource and take it's first level children... 
            target.children.each do |ao|
              # this is the baseline for all the barcodes we'll generate.. 
              barcode = "aspace.#{ao.id}" 
              # we look it there are an 
              updated_records += process_children( ao, barcode)  
            end
            @job.write_output( "Finishing #{target.id}" ) 
            @job.record_created_uris(updated_records.uniq) 
          end 
        rescue Exception => e
          terminal_error = e
          @job.write_output(terminal_error.message)
          @job.write_output(terminal_error.backtrace)
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
