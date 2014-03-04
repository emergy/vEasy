vEasy
=====

What is vEasy?
--------------

vEasy is automation framework for VMware vSphere infrastructure. It utilizes the VMware vSphere API and has been built on top of VMware vSphere SDK for Perl. With vEasy Automation Framework you can more easily automate management and data collection of your vSphere Infrastructure without in-depth knowledge of vSphere API. vEasy contains a package for each Managed Entity object (VirtualMachine, Cluster, HostSystem, Folder, ResourcePool etc...) in vSphere Infrastructure. 

vEasy is still incomplete and not extensively tested. You should not run it in production systems yet.

See [Documentation](https://github.com/aaremiz/vEasy/wiki/) and [Quick Start Guide](https://github.com/aaremiz/vEasy/wiki/QuickStartGuide) for more info.

Design Principals
-----------------

* To easy management/automation/data collection of/from VMware vSphere Infrastructure.
* VMware vSphere automation without in-depth knowledge about the vSphere API.
* Mimimum amount of parameters in each function
* Function parameters are only names (string), numbers (int) or vEasy objects
* Every function has a return value
* Function return values are only (if possible) booleans, strings, numbers or vEasy objects. Not vSphere API objects etc.
* vEasy is generic
* No additional Perl packages required (addition to VMware vSphere SDK for Perl requirements)
* Using vEasy framework does not prevent usage of VMware vSphere API in other ways not defined in vEasy: 
	* vEasy can be easily integrated to existing products.
	* vEasy can be used as a base for more complex products.
* Centralized Fault Management


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

#####vEasy Documentation
https://github.com/aaremiz/vEasy/wiki

#####vEasy Examples
https://github.com/aaremiz/vEasy-Examples

#####VMware vSphere API Reference:
https://www.vmware.com/support/developer/vc-sdk/
 
#####VMware vSphere SDK for Perl Documentation:
https://www.vmware.com/support/developer/viperltoolkit/

License
-------

vEasy is distributed under the terms of BSD 3-Clause License. See LICENSE file.

```
Copyright (c) 2014, Risto Mäntylä
All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice, this
  list of conditions and the following disclaimer in the documentation and/or
  other materials provided with the distribution.

* Neither the name of the author nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

