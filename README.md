# ArchivesSpace Barcoder Plugin

This plugin creates a job that will generate barcodes for containers associated to a resource by
taking the ID of the highest archival object ancestor and combining the container's type_1 and
instance_1 fields. 

For example, Resource ( 123 ) --> ArchivalObject ( 456 ) --> ArchivalObject ( 789 ) --> Instance --> Container ( Type: Box,
Indicator: 1 ) will be given a barcode of 'aspace.456.Box.1'.

# Why? 


Some institutions reset their boxes at some levels, which can cause problems when converting containers to the new
container management scheme. With these generated barcodes, you can now have multple "Box 1"s in a resource.

For example:
Resource ( 123 )-->ArchivalObject ( 456 )-->ArchivalObject ( 789 )-->Instance-->Container ( Box:1 Barcode:aspace.456.Box.1 )
Resource ( 123 )-->ArchivalObject ( 654 )-->ArchivalObject ( 111 )-->Instance-->Container ( Box:1 Barcode:aspace.654.Box.1 )

See? There are now two seperate "Box 1" containers that are differentited by their barcode. 

## To Install:

1.Download and unpack the plugin to your ArchivesSpace plugins directory. Make
sure the name of the directory is "barcoder"  ( not "barcoder-master" or any
other branch information Github adds )
2.Add "barcoder" to your config/config.rb AppConfig[:plugins] list
3.Restart ArchivesSpace

## To Use:
Logged in as a repository administrator, go to Plugins --> Barcode Resources. 
Select a Resource in the linker box and click submit.

## To Uninstall:

You will need to remove any job record in your database that point to this:
```
DELETE FROM job WHERE job_type_id = ( SELECT id from enumeration_value WHERE
value = 'barcoder_job' ); )
```

And you might as well delete the enumeration value as well: 
```
DELETE FROM enumeration_value WHERE value = 'barcoder_job';
```

Then remove the barcoder_job value from your config/config.rb
AppConfig[:plugins] list. 


