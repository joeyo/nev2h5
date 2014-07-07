# nev2h5 

Convert .nev file from Blackrock Microsystems to hdf5, drop all waveforms

## Usage

nev2hdf5 [INPUT_FILE] [OUTPUT_FILE]

If OUTPUT_FILE does not extension .h5, it will be appended automatically

The output structure is as follows:  
file---attrs---timeOrigin  
     |      |-resoltuion  
     |      |-comment  
     |      |-mapfile  
     |      |-arrayName  
     |-events---dset---attrs---eventID  
     |        |      |-timestamps  
     |        |-dset...  
     |-channels  
