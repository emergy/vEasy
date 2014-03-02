vEasy
=====

vEasy is still incomplete and not very well tested. You should not run it in production systems yet.

License
-------

This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

What is vEasy?
--------------

vEasy is automation framework for VMware vSphere infrastructure. It utilizes the VMware vSphere API and has been built on top of VMware vSphere SDK for Perl. With vEasy Automation Framework you can more easily automate management and data collection of your vSphere Infrastructure without in-depth knowledge of vSphere API. vEasy contains a package for each Managed Entity object (VirtualMachine, Cluster, HostSystem, Folder, ResourcePool etc...) in vSphere Infrastructure. 

Design Principals
-----------------

- To easy management/automation/data collection of/from VMware vSphere Infrastructure.
- VMware vSphere automation without in-depth knowledge about the vSphere API.
- Mimimum amount of parameters in each function
- Function parameters are only names (string), numbers (int) or vEasy objects
- Every function has a return value
- Function return values are only (if possible) booleans, strings, numbers or vEasy objects. Not vSphere API objects etc.
- vEasy is generic
- No additional Perl packages required (addition to VMware vSphere SDK for Perl requirements)
- Using vEasy framework does not prevent usage of VMware vSphere API in other ways not defined in vEasy: 
		- vEasy can be easily integrated to existing products.
		- vEasy can be used as a base for more complex products.
- Centralized Fault Management


Tested with
-----------
- vMA 5.1 update 2
- vMA 5.5.0b
- VMware vSphere SDK for Perl 5.1 + CentOS 6.5
- vCenter 5.1 update 2
- vCenter 5.5.0b
- ESXi 5.1
- ESXi 5.5

Documentation
---------------

Before you start to use vEasy it is recommended that you read VMware vSphere SDK for Perl programming guide (check the link below) to get the basic knowledge about VMware vSphere API and terminology used in it. 

vEasy Documentation
https://github.com/aaremiz/vEasy/wiki

VMware vSphere API Reference:
https://www.vmware.com/support/developer/vc-sdk/
 
VMware vSphere SDK for Perl Documentation:
https://www.vmware.com/support/developer/viperltoolkit/

