Gerty software architecture
===========================

Introduction
------------

Gerty is designed to be a replacement to RANCID software, and much more.
While RANCID is mainly concentrated on router configuration backup, and
there's Cisco in its name, Gerty is different:

*   Generic Telnet/SSH/whatever output processing tool.
    Router configuration is still the important part of the output, but
    we can do more.

*   Pluggable architecture.
    Some standard modules come with the main
    distribution, some modules are distributed as plugins, and the user
    can add their own modules without messing up with the original files
    that were installed by Gerty and its plugins.

*   Vendor neutrality.
    We are not concentrated on Cisco.

*   Support for interactive processing.
    New CLI commands may depend on the output of previous ones

*   Hooks for automatic output validation.
    You may need to verify the configuration against some
    inventory databases, check that it conforms to some templates, etc.

Gerty is completely written in Perl. Also all custom hooks and
processing tools are expected to be in Perl.


Job configuration
-----------------

Every run cycle of Gerty is defined by a corresponding job configuration.
Job configurations are expected in INI file format, although `Config::Any`
Perl module allows also JSON, XML, and other formats.

The job definition file consists of a number of sections, and these sections
are processed hierarchically: the job consists of device lists, and each
device list defines some attributes which are used by each individual device.

Some attributes belong to their specific area. For example, the *devlists* 
attribute is only used in the *[job]* section in the job definition file.

Device attributes, those which define the Gerty's behavior at the device 
level, are looked up in a hierarchical fashion, from the top parent class to 
the job level. See *Gerty Device Attributes* document for details.

Example of a job file (**/opt/gerty/Company/jobs/backbone.job.ini**):

    [job]
      ; in further examples, we refer to the company name as Company
      title = Company MPLS Backbone Routers
      description = "Configs, LDP, and BGP statistics from core routers"

      ; split the job among 10 child processes
      parallel = 10

      ; here Gerty looks for Company specific modules, such as device class
      ; definitions or custom processing hooks
      siteconfig = /opt/gerty/Company
      
      ; refer to the device lists defined in siteconfigs
      devlists = cisco-7600-pe, juniper-mx-pe
      
Example of a siteconfig file (**/opt/gerty/Company/siteconfig.ini**):
    
    [siteconfig]
      ; we use SSH globally everywhere
      cli.access-method:default = ssh

      ; example of a user-defined variable
      backbone-data = /srv/gerty/backbone

      ; if not specified explicitly, the output files are saved here
      output.default-path = ${backbone-data}/out

    [devices cisco-7600-pe]
      description = "Cisco 7600 series as MPLS PE routers"

      ; take the list of devices from a file.
      ; alternatively this can be SQL or SOAP or whatever query
      source.type = Gerty::DeviceList::File

      ; attributes specific to this source type
      source.filename = ${backbone-data}/nodelists/cisco7600pe

      ; import devices from a plain text. Alternatively this could be XML or
      ; some other format supported by Gerty::Devlist::File
      source.filetype = plain

      ; here we distinguish between the system name as it's stored in
      ; Gerty output, its network address (could be a FQDN or IPv4/6 address),
      ; and free-form device description. These elements are expected to
      ; be separated with double slashes
      source.delimiter = \/\/
      source.fields = SYSNAME, ADDRESS, DESCRIPTION

      ; device class defines all Gerty's behavior for these devices.
      ; source can also define alternative device types
      ; (DEVCLASS in source.fields)
      devclass = Company.Cisco7600PE


    [devices juniper-mx-pe]
      description = "Juniper MX series as MPLS PE routers"

      ; example of SQL import
      source.type = Gerty::DeviceList::DBI

      ; Database connection attributes
      source.dsn = DBI:mysql:database=inventory;host=dbhost
      source.username = gerty
      source.password = Ieweeph8ja

      ; only a short SQL query for the sake of readability (INI format does not
      ; allow multi-line values)
      source.query = SELECT NODE, ADDR, DESCRIPTION FROM V_DEVLIST

      ; tell Gerty positions in the result row
      source.fields = SYSNAME, ADDRESS, DESCRIPTION

      devclass = Company.JuniperMXPE

Example of a devclass file 
(**/opt/gerty/Company/devclases/Company.Cisco7600PE.ini**):

    [devclass Company.Cisco7600PE]

      ; properties from generic and Company specific modules
      ; a rule of thumb: generic devclasses define a set of possible actions 
      ; and reports, but particular actions have to be activated here
      inherit = Gerty.CiscoIOS, Company.Generic

      ; this tells that we use admin privileges ("enable" in Cisco terminology)
      admin-mode = 1

      ; access credentials are better to define in a Company-specific devclass,
      ; but we define it here for simplicity.

      ; placeholder for other ways to retrieve passwords (a better way is to
      ; store passwords externally, or even retrieve OTP from somewhere)
      credentials-source = inline

      ; login credentials
      cli.auth-username = gerty
      cli.auth-password = eeDie6louj

      ; enable password is used by "Gerty.CiscoIOS" and only when 
      ; admin-mode is true
      cli.auth-epassword = Ieyei5ofej

      ;;; enable the actions (they are defined in modules 
      ;;; like "Gerty.CiscoIOS")

      ; "do.config-backup" is a standard action name, implemented differently
      ; for various vendor types. It also requires a number of attributes
      ; that define the storage
      do.config-backup = 1
      config-backup.path = ${backbone-data}/cfgbackup

      config-backup.postprocess = Company::Postprocess

      ; "sh ver", "sh module", etc. It is an interactive script,
      ; doing additional disagostics depending on HW type
      do.cisco-diags = 1

      ; store this separately from configuration
      cisco-diags.path = ${backbone-data}/diag

      ; routing protocols statistics
      do.protocol-bgp = 1
      do.protocol-isis = 1
      do.protocol-ldp = 1
      protocols.path = ${backbone-data}/protocols


Directory structure
-------------------

The Gerty package installer delivers a number of standarrd directories and
files, as described below. Here paths are relative to some standard prefix,
such as `/usr/local` or `/opt/gerty`, or whatever the administrator used to 
install the package.
The users and site administrators would never have a need to modify
anything in them, and the files would be overwritten by the package installer.


*   `lib/perl/Gerty` -- the directory with Perl modules that are installed
    by Gerty installer and plugins
*   `bin/gerty` -- the only user executable. It dispatches the calls to
    various functionality modules. Plugins can also add new subcommands and
    options.
*   `share/gerty/devclasses/` -- the directory with INI files that define
    predefined device classes, such as `Gerty.CiscoIOS.ini`
*   `share/gerty/plugins` -- the directory where the plugin installers put 
    their configuration files


Everything that a local user or the server administrator would need to define
belongs to **siteconfig**. There is no limit in the number of siteconfigs:
for example, a user can create their own siteconfig for some testing purposes
before deploying the configuration to the productive siteconfig.

Siteconfig is meant to be a relatively stable set of data. It usually
describes the program behavior, while the dynamic data, such as lists of
device names, is stored elsewhere (`/srv/gerty/...` or `/var/opt/gerty/...`
are possible candidates for such data).

Siteconfig is a directory with some predefined elements, as follows:

*   `devclasses/` -- INI files for site-specific device class definitions
*   `siteconfig.ini` -- optional configuration file that refers to
    some external entities, such as Company's Perl modules for
    Gerty extensions. Also some site globals could be defined here instead of
    the job definition file.
*   `lib/Company/` -- optional path where Gerty looks for Perl modules
*   `jobs/` -- preferred place for job definitions, although they can be 
    stored anywhere.


Author
------

Stanislav Sinyagin  
CCIE #5478  
ssinyagin@k-open.com  
+41 79 407 0224  



